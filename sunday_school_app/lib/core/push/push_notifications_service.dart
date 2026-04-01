import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../routing/app_router.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If Firebase isn't configured yet, we don't want to crash the process.
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class PushNotificationsService {
  PushNotificationsService._();

  static final PushNotificationsService instance = PushNotificationsService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<String>? _tokenRefreshSub;
  RealtimeChannel? _announcementsChannel;

  String? _currentToken;
  String? _pendingNavigationLocation;
  bool _initialized = false;

  final Map<String, int> _recentOnlineNoticeIds = {};

  String _formatLabel(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return '';
    final parts = raw
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return parts
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _truncateText(String input, int max) {
    final text = input.trim();
    if (text.length <= max) return text;
    final cut = (max - 3).clamp(0, max);
    return '${text.substring(0, cut).trimRight()}...';
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    var firebaseReady = false;

    try {
      await Firebase.initializeApp();
      firebaseReady = true;
    } catch (e) {
      // Firebase native config might not be present yet.
      if (kDebugMode) {
        debugPrint('PushNotificationsService: Firebase not configured ($e)');
      }
    }

    await _initLocalNotifications();

    if (firebaseReady) {
      await _requestNotificationPermissionIfNeeded();
    } else {
      // Still request local notification permission (Android 13+), even if
      // Firebase isn't available.
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }

    if (!firebaseReady) {
      // Online fallback (Realtime) still works without Firebase.
      await _startOnlineAnnouncementFallbackIfNeeded();
      return;
    }

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      unawaited(_handleNotificationOpen(data: message.data));
    });

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      unawaited(_handleNotificationOpen(data: initial.data));
    }

    FirebaseMessaging.onMessage.listen((message) {
      // Show a heads-up notification while the app is foregrounded.
      unawaited(_showForegroundNotification(message));
    });

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedOut) {
        unawaited(_stopOnlineAnnouncementFallback());
        // NOTE: Once signed out, RLS will usually prevent deleting the token row.
        // Call `unregisterBeforeSignOut()` before `auth.signOut()` instead.
        return;
      }

      if (state.session != null) {
        unawaited(_registerCurrentToken());
        unawaited(_startOnlineAnnouncementFallbackIfNeeded());
      }
    });

    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _currentToken = token;
      if (kDebugMode) {
        debugPrint('PushNotificationsService: token refreshed (len=${token.length})');
      }
      unawaited(_registerToken(token));
    });

    _currentToken = await FirebaseMessaging.instance.getToken();
    if (kDebugMode) {
      final token = _currentToken;
      debugPrint(
        'PushNotificationsService: initial token ${token == null ? 'null' : 'len=${token.length}'}',
      );
    }
    await _registerCurrentToken();
    await _startOnlineAnnouncementFallbackIfNeeded();
  }

  Future<void> _startOnlineAnnouncementFallbackIfNeeded() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    if (_announcementsChannel != null) return;

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role, grade_id')
          .eq('id', userId)
          .maybeSingle();

      final role = profile?['role']?.toString().trim().toLowerCase();
      if (role != 'student' && role != 'servant') return;

      final gradeId = profile?['grade_id']?.toString();
      final client = Supabase.instance.client;

      final channel = client.channel('online-announcements-$userId');
      _announcementsChannel = channel;

      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'announcements',
        callback: (payload) async {
          final record = Map<String, dynamic>.from(payload.newRecord);

          final announcementId = record['id']?.toString();
          if (announcementId == null || announcementId.isEmpty) return;

          final nowMs = DateTime.now().millisecondsSinceEpoch;
          _recentOnlineNoticeIds.removeWhere((_, ts) => nowMs - ts > 10 * 60 * 1000);
          if (_recentOnlineNoticeIds.containsKey(announcementId)) return;
          _recentOnlineNoticeIds[announcementId] = nowMs;

          final active = record['active'];
          if (active is bool && active == false) return;

          final expiresOn = record['expires_on']?.toString();
          if (expiresOn != null && expiresOn.trim().isNotEmpty) {
            final exp = DateTime.tryParse(expiresOn);
            if (exp != null && exp.isBefore(DateTime.now())) return;
          }

          final createdBy = record['created_by']?.toString();
          if (createdBy != null && createdBy == userId) return;

          final announcementGradeId = record['grade_id']?.toString();
          if (gradeId != null && gradeId.isNotEmpty) {
            // If the announcement targets another grade, ignore it.
            if (announcementGradeId != null && announcementGradeId.isNotEmpty && announcementGradeId != gradeId) {
              return;
            }
          }

          final categoryRaw = record['category']?.toString() ?? 'general';
          final categoryLabel = _formatLabel(categoryRaw);
          final title = 'Announcement • ${categoryLabel.isEmpty ? 'General' : categoryLabel}';

          final annTitle = record['title']?.toString() ?? '';
          final message = record['message']?.toString() ?? '';
          final body = [
            if (annTitle.trim().isNotEmpty) _truncateText(annTitle, 80),
            if (message.trim().isNotEmpty) _truncateText(message, 120),
          ].join(' — ');

          final notifPayload = jsonEncode({'type': 'announcement', 'id': announcementId});

          const androidDetails = AndroidNotificationDetails(
            'communications',
            'Communications',
            channelDescription: 'Announcements and communication updates',
            importance: Importance.high,
            priority: Priority.high,
          );
          const details = NotificationDetails(android: androidDetails);

          try {
            await _localNotifications.show(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: title,
              body: body,
              notificationDetails: details,
              payload: notifPayload,
            );
          } catch (_) {}
        },
      );

      channel.subscribe();
    } catch (_) {
      await _stopOnlineAnnouncementFallback();
    }
  }

  Future<void> _stopOnlineAnnouncementFallback() async {
    final channel = _announcementsChannel;
    _announcementsChannel = null;
    if (channel == null) return;
    try {
      await channel.unsubscribe();
    } catch (_) {}
  }

  /// Removes this device token from `device_push_tokens` while the user is still
  /// authenticated.
  ///
  /// This must be called before `Supabase.instance.client.auth.signOut()`;
  /// otherwise RLS will block the delete.
  Future<void> unregisterBeforeSignOut() async {
    await _unregisterToken();
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        unawaited(_handleNotificationOpen(payload: response.payload));
      },
    );

    const channel = AndroidNotificationChannel(
      'communications',
      'Communications',
      description: 'Announcements and communication updates',
      importance: Importance.high,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
  }

  Future<void> _requestNotificationPermissionIfNeeded() async {
    // Android 13+: runtime permission.
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    // iOS/macOS.
    await FirebaseMessaging.instance.requestPermission();
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? 'New update';
    final body = notification?.body ?? '';

    final idFromData = message.data['id']?.toString();
    if (idFromData != null && idFromData.trim().isNotEmpty) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      _recentOnlineNoticeIds.removeWhere((_, ts) => nowMs - ts > 10 * 60 * 1000);
      if (_recentOnlineNoticeIds.containsKey(idFromData)) {
        return;
      }
      _recentOnlineNoticeIds[idFromData] = nowMs;
    }

    const androidDetails = AndroidNotificationDetails(
      'communications',
      'Communications',
      channelDescription: 'Announcements and communication updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    final payload = jsonEncode({
      'type': message.data['type']?.toString(),
      'id': message.data['id']?.toString(),
    });

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> _handleNotificationOpen({Map<String, dynamic>? data, String? payload}) async {
    String? type;
    String? id;

    if (data != null) {
      type = data['type']?.toString();
      id = data['id']?.toString();
    }

    if ((type == null || type.isEmpty) && payload != null && payload.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(payload) as Map<String, dynamic>;
        type = decoded['type']?.toString();
        id = decoded['id']?.toString();
      } catch (_) {}
    }

    final tab = switch ((type ?? '').trim().toLowerCase()) {
      'announcement' => 'announcements',
      'question_answered' => 'questions',
      'complaint_responded' => 'complaints',
      'feedback_form_created' => 'feedback',
      _ => null,
    };

    final base = await _resolveCommunicationBasePath();
    if (base == null) {
      _navigateTo('/');
      return;
    }

    final uri = Uri(
      path: base,
      queryParameters: {
        'tab': ?tab,
        if (id != null && id.isNotEmpty) 'id': id,
      },
    );

    _navigateTo(uri.toString());
  }

  Future<String?> _resolveCommunicationBasePath() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      final role = profile?['role']?.toString().trim().toLowerCase();
      if (role == 'servant') return '/servant/communication';
      if (role == 'student') return '/student/communication';
    } catch (_) {}

    return null;
  }

  void _navigateTo(String location) {
    if (rootNavigatorKey.currentContext != null) {
      appRouter.go(location);
      return;
    }

    _pendingNavigationLocation = location;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = _pendingNavigationLocation;
      if (pending == null) return;
      if (rootNavigatorKey.currentContext == null) return;
      _pendingNavigationLocation = null;
      appRouter.go(pending);
    });
  }

  Future<void> _registerCurrentToken() async {
    final token = _currentToken;
    if (token == null || token.isEmpty) return;
    await _registerToken(token);
  }

  Future<void> _registerToken(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };

    try {
      await Supabase.instance.client.from('device_push_tokens').upsert(
        {
          'user_id': userId,
          'fcm_token': token,
          'platform': platform,
          'enabled': true,
          'last_seen_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'fcm_token',
      );
      if (kDebugMode) {
        debugPrint('PushNotificationsService: token upsert OK');
      }
    } catch (e) {
      // Ignore: table may not be migrated yet or RLS may block.
      if (kDebugMode) {
        debugPrint('PushNotificationsService: token upsert FAILED ($e)');
      }
    }
  }

  Future<void> _unregisterToken() async {
    final token = _currentToken;
    if (token == null || token.isEmpty) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client
          .from('device_push_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('fcm_token', token);
      if (kDebugMode) {
        debugPrint('PushNotificationsService: token delete OK');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PushNotificationsService: token delete FAILED ($e)');
      }
    }
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
    await _tokenRefreshSub?.cancel();
    await _stopOnlineAnnouncementFallback();
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sunday_school_app/l10n/app_localizations.dart';

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
  _LifecycleObserver? _lifecycleObserver;

  final Map<String, int> _recentOnlineNoticeIds = {};

  bool _catchupRunning = false;
  DateTime? _lastCatchupAttemptAt;
  int _notificationIdCounter = 0;

  String? _dedupeKey(String? type, String? id) {
    final rawId = id?.trim();
    if (rawId == null || rawId.isEmpty) return null;
    final rawType = type?.trim().toLowerCase();
    if (rawType == null || rawType.isEmpty) return rawId;
    return '$rawType:$rawId';
  }

  void _pruneRecentNoticeIds() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _recentOnlineNoticeIds.removeWhere((_, ts) => nowMs - ts > 10 * 60 * 1000);
  }

  int _nextNotificationId() {
    // Keep ids small (32-bit) for Android.
    final base = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final offset = _notificationIdCounter++ % 1000;
    return base + offset;
  }

  AppLocalizations _resolveL10n() {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null) {
      return AppLocalizations.of(ctx);
    }

    try {
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      return lookupAppLocalizations(locale);
    } catch (_) {
      return lookupAppLocalizations(const Locale('en'));
    }
  }

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

  String _announcementCategoryLabel(String raw, AppLocalizations l10n) {
    switch (raw.trim().toLowerCase()) {
      case 'urgent':
        return l10n.commAnnouncementCategoryUrgent;
      case 'grades':
        return l10n.commAnnouncementCategoryGrades;
      case 'schedule':
        return l10n.commAnnouncementCategorySchedule;
      case 'event':
        return l10n.commAnnouncementCategoryEvent;
      case 'general':
        return l10n.commAnnouncementCategoryGeneral;
      default:
        return _formatLabel(raw);
    }
  }

  AndroidNotificationDetails _androidNotificationDetails(
    AppLocalizations l10n,
  ) {
    return AndroidNotificationDetails(
      'communications',
      l10n.pushChannelCommunicationsName,
      channelDescription: l10n.pushChannelCommunicationsDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _lifecycleObserver ??= _LifecycleObserver(this);
    WidgetsBinding.instance.addObserver(_lifecycleObserver!);

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    var firebaseReady = false;

    try {
      await Firebase.initializeApp();
      firebaseReady = true;
    } catch (e) {
      // Already initialized (e.g. by crash reporting) is fine; otherwise the
      // Firebase native config might not be present yet.
      if (Firebase.apps.isNotEmpty) {
        firebaseReady = true;
      } else if (kDebugMode) {
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
            AndroidFlutterLocalNotificationsPlugin
          >();
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
        unawaited(_handleSignedIn());
      }
    });

    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((
      token,
    ) {
      _currentToken = token;
      if (kDebugMode) {
        debugPrint(
          'PushNotificationsService: token refreshed (len=${token.length})',
        );
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
    await _handleSignedIn();
  }

  Future<void> _handleSignedIn() async {
    await _registerCurrentToken();
    await _catchUpMissedNotificationsIfNeeded();
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

          final dedupeKey = _dedupeKey('announcement', announcementId);
          if (dedupeKey != null) {
            _pruneRecentNoticeIds();
            if (_recentOnlineNoticeIds.containsKey(dedupeKey)) return;
            _recentOnlineNoticeIds[dedupeKey] =
                DateTime.now().millisecondsSinceEpoch;
          }

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
            if (announcementGradeId != null &&
                announcementGradeId.isNotEmpty &&
                announcementGradeId != gradeId) {
              return;
            }
          }

          final l10n = _resolveL10n();
          final categoryRaw = record['category']?.toString() ?? 'general';
          final categoryLabel = _announcementCategoryLabel(categoryRaw, l10n);
          final title =
              '${l10n.commAnnouncements} • ${categoryLabel.isEmpty ? l10n.commAnnouncementCategoryGeneral : categoryLabel}';

          final annTitle = record['title']?.toString() ?? '';
          final message = record['message']?.toString() ?? '';
          final body = [
            if (annTitle.trim().isNotEmpty) _truncateText(annTitle, 80),
            if (message.trim().isNotEmpty) _truncateText(message, 120),
          ].join(' — ');

          final notifPayload = jsonEncode({
            'type': 'announcement',
            'id': announcementId,
          });

          final androidDetails = _androidNotificationDetails(l10n);
          const iosDetails = DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          );
          final details = NotificationDetails(
            android: androidDetails,
            iOS: iosDetails,
          );

          try {
            await _localNotifications.show(
              id: _nextNotificationId(),
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
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        unawaited(_handleNotificationOpen(payload: response.payload));
      },
    );

    final l10n = _resolveL10n();
    final channel = AndroidNotificationChannel(
      'communications',
      l10n.pushChannelCommunicationsName,
      description: l10n.pushChannelCommunicationsDescription,
      importance: Importance.high,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(channel);
  }

  Future<void> _requestNotificationPermissionIfNeeded() async {
    // Android 13+: runtime permission.
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();

    // iOS/macOS.
    await FirebaseMessaging.instance.requestPermission();
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final l10n = _resolveL10n();
    final title = notification?.title ?? l10n.pushNotificationNewUpdateTitle;
    final body = notification?.body ?? '';

    final dedupeKey = _dedupeKey(
      message.data['type']?.toString(),
      message.data['id']?.toString(),
    );
    if (dedupeKey != null) {
      _pruneRecentNoticeIds();
      if (_recentOnlineNoticeIds.containsKey(dedupeKey)) {
        return;
      }
      _recentOnlineNoticeIds[dedupeKey] = DateTime.now().millisecondsSinceEpoch;
    }

    final androidDetails = _androidNotificationDetails(l10n);

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = jsonEncode({
      'type': message.data['type']?.toString(),
      'id': message.data['id']?.toString(),
    });

    await _localNotifications.show(
      id: _nextNotificationId(),
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<DateTime?> _loadLastSeenAt() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final token = _currentToken;
    if (userId == null || token == null || token.isEmpty) return null;

    final client = Supabase.instance.client;
    try {
      final row = await client
          .from('device_push_tokens')
          .select('last_seen_at')
          .eq('user_id', userId)
          .eq('fcm_token', token)
          .maybeSingle();

      final raw = (row as Map?)?['last_seen_at']?.toString();
      if (raw == null || raw.trim().isEmpty) return null;
      return DateTime.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _touchLastSeenAt([DateTime? ts]) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final token = _currentToken;
    if (userId == null || token == null || token.isEmpty) return;

    final client = Supabase.instance.client;
    try {
      await client
          .from('device_push_tokens')
          .update({'last_seen_at': (ts ?? DateTime.now()).toIso8601String()})
          .eq('user_id', userId)
          .eq('fcm_token', token);
    } catch (_) {}
  }

  Future<void> _catchUpMissedNotificationsIfNeeded() async {
    final now = DateTime.now();
    if (_catchupRunning) return;

    final lastAttempt = _lastCatchupAttemptAt;
    if (lastAttempt != null &&
        now.difference(lastAttempt) < const Duration(seconds: 10)) {
      return;
    }
    _lastCatchupAttemptAt = now;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final token = _currentToken;
    if (token == null || token.isEmpty) return;

    _catchupRunning = true;
    try {
      final since = await _loadLastSeenAt();

      // First install / first login on this device: establish baseline but
      // don't spam old notifications.
      if (since == null) {
        await _touchLastSeenAt(now);
        return;
      }

      final client = Supabase.instance.client;
      final profile = await client
          .from('profiles')
          .select('role, grade_id')
          .eq('id', userId)
          .maybeSingle();

      final role = (profile as Map?)?['role']?.toString().trim().toLowerCase();
      final gradeId = (profile as Map?)?['grade_id']?.toString();
      if (role != 'student' && role != 'servant') {
        await _touchLastSeenAt(now);
        return;
      }

      await _catchUpAnnouncements(
        client: client,
        userId: userId,
        gradeId: gradeId,
        since: since,
      );

      if (role == 'student') {
        await _catchUpFeedbackForms(
          client: client,
          gradeId: gradeId,
          since: since,
        );
        await _catchUpAnsweredQuestions(
          client: client,
          userId: userId,
          since: since,
        );
        await _catchUpRespondedComplaints(
          client: client,
          userId: userId,
          since: since,
        );
      }

      await _touchLastSeenAt(now);
    } catch (_) {
      // If any step fails (offline/RLS/etc), do not advance last_seen_at.
    } finally {
      _catchupRunning = false;
    }
  }

  Future<void> _catchUpAnnouncements({
    required SupabaseClient client,
    required String userId,
    required String? gradeId,
    required DateTime since,
  }) async {
    try {
      var q = client
          .from('announcements')
          .select(
            'id,title,message,category,created_by,created_at,expires_on,active,grade_id',
          )
          .eq('active', true)
          .gt('created_at', since.toIso8601String())
          .neq('created_by', userId);

      if (gradeId != null && gradeId.trim().isNotEmpty) {
        q = q.or('grade_id.is.null,grade_id.eq.$gradeId');
      }

      final rows = await q.order('created_at', ascending: true);
      final l10n = _resolveL10n();

      for (final r in rows as List) {
        final map = r as Map;
        final id = map['id']?.toString();
        if (id == null || id.isEmpty) continue;

        final expiresOn = map['expires_on']?.toString();
        if (expiresOn != null && expiresOn.trim().isNotEmpty) {
          final exp = DateTime.tryParse(expiresOn);
          if (exp != null && exp.isBefore(DateTime.now())) continue;
        }

        final key = _dedupeKey('announcement', id);
        if (key != null) {
          _pruneRecentNoticeIds();
          if (_recentOnlineNoticeIds.containsKey(key)) continue;
          _recentOnlineNoticeIds[key] = DateTime.now().millisecondsSinceEpoch;
        }

        final categoryRaw = map['category']?.toString() ?? 'general';
        final categoryLabel = _announcementCategoryLabel(categoryRaw, l10n);
        final title =
            '${l10n.commAnnouncements} • ${categoryLabel.isEmpty ? l10n.commAnnouncementCategoryGeneral : categoryLabel}';

        final annTitle = map['title']?.toString() ?? '';
        final message = map['message']?.toString() ?? '';
        final body = [
          if (annTitle.trim().isNotEmpty) _truncateText(annTitle, 80),
          if (message.trim().isNotEmpty) _truncateText(message, 120),
        ].join(' — ');

        final payload = jsonEncode({'type': 'announcement', 'id': id});
        await _showLocalNotification(
          title: title,
          body: body,
          payload: payload,
        );
      }
    } catch (_) {}
  }

  Future<void> _catchUpFeedbackForms({
    required SupabaseClient client,
    required String? gradeId,
    required DateTime since,
  }) async {
    if (gradeId == null || gradeId.trim().isEmpty) return;
    try {
      final rows = await client
          .from('feedback_forms')
          .select('id,title,description,type_label,created_at')
          .eq('grade_id', gradeId)
          .gt('created_at', since.toIso8601String())
          .order('created_at', ascending: true);

      final l10n = _resolveL10n();
      for (final r in rows as List) {
        final map = r as Map;
        final id = map['id']?.toString();
        if (id == null || id.isEmpty) continue;

        final key = _dedupeKey('feedback_form_created', id);
        if (key != null) {
          _pruneRecentNoticeIds();
          if (_recentOnlineNoticeIds.containsKey(key)) continue;
          _recentOnlineNoticeIds[key] = DateTime.now().millisecondsSinceEpoch;
        }

        final typeLabel = _formatLabel(map['type_label']?.toString() ?? '');
        final title =
            '${l10n.commFeedback} • ${typeLabel.isEmpty ? l10n.commFeedback : typeLabel}';
        final formTitle = map['title']?.toString() ?? '';
        final description = map['description']?.toString() ?? '';
        final body = [
          if (formTitle.trim().isNotEmpty) _truncateText(formTitle, 90),
          if (description.trim().isNotEmpty) _truncateText(description, 120),
        ].join(' — ');

        final payload = jsonEncode({'type': 'feedback_form_created', 'id': id});
        await _showLocalNotification(
          title: title,
          body: body,
          payload: payload,
        );
      }
    } catch (_) {}
  }

  Future<void> _catchUpAnsweredQuestions({
    required SupabaseClient client,
    required String userId,
    required DateTime since,
  }) async {
    try {
      final rows = await client
          .from('questions')
          .select('id,answer,answered_at')
          .eq('student_id', userId)
          .eq('answered', true)
          .gt('answered_at', since.toIso8601String())
          .order('answered_at', ascending: true);

      final l10n = _resolveL10n();
      final title = l10n.pushNotificationQuestionAnsweredTitle;

      for (final r in rows as List) {
        final map = r as Map;
        final id = map['id']?.toString();
        if (id == null || id.isEmpty) continue;

        final key = _dedupeKey('question_answered', id);
        if (key != null) {
          _pruneRecentNoticeIds();
          if (_recentOnlineNoticeIds.containsKey(key)) continue;
          _recentOnlineNoticeIds[key] = DateTime.now().millisecondsSinceEpoch;
        }
        final answer = map['answer']?.toString() ?? '';
        final body = _truncateText(answer, 120);
        final payload = jsonEncode({'type': 'question_answered', 'id': id});
        await _showLocalNotification(
          title: title,
          body: body,
          payload: payload,
        );
      }
    } catch (_) {}
  }

  Future<void> _catchUpRespondedComplaints({
    required SupabaseClient client,
    required String userId,
    required DateTime since,
  }) async {
    try {
      final rows = await client
          .from('complaints')
          .select('id,response,responded_at')
          .eq('student_id', userId)
          .gt('responded_at', since.toIso8601String())
          .order('responded_at', ascending: true);

      final l10n = _resolveL10n();
      final title = l10n.pushNotificationComplaintRespondedTitle;

      for (final r in rows as List) {
        final map = r as Map;
        final id = map['id']?.toString();
        if (id == null || id.isEmpty) continue;

        final key = _dedupeKey('complaint_responded', id);
        if (key != null) {
          _pruneRecentNoticeIds();
          if (_recentOnlineNoticeIds.containsKey(key)) continue;
          _recentOnlineNoticeIds[key] = DateTime.now().millisecondsSinceEpoch;
        }
        final response = map['response']?.toString() ?? '';
        final body = _truncateText(response, 120);
        final payload = jsonEncode({'type': 'complaint_responded', 'id': id});
        await _showLocalNotification(
          title: title,
          body: body,
          payload: payload,
        );
      }
    } catch (_) {}
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    final l10n = _resolveL10n();
    final androidDetails = _androidNotificationDetails(l10n);
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: _nextNotificationId(),
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> _handleNotificationOpen({
    Map<String, dynamic>? data,
    String? payload,
  }) async {
    Session? session;
    try {
      session = Supabase.instance.client.auth.currentSession;
    } catch (_) {
      session = null;
    }

    // If signed out, do not deep-link into role areas (which would otherwise
    // bounce into login and feel like the app "opened the account").
    if (session == null) {
      _navigateTo('/');
      return;
    }

    String? type;
    String? id;

    if (data != null) {
      type = data['type']?.toString();
      id = data['id']?.toString();
    }

    if ((type == null || type.isEmpty) &&
        payload != null &&
        payload.trim().isNotEmpty) {
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
        ...?(tab == null ? null : {'tab': tab}),
        if (id != null && id.isNotEmpty) 'id': id,
      },
    );

    _navigateTo(uri.toString());
  }

  Future<String?> _resolveCommunicationBasePath() async {
    final userId = Supabase.instance.client.auth.currentSession?.user.id;
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
      await Supabase.instance.client.from('device_push_tokens').upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': platform,
        'enabled': true,
      }, onConflict: 'fcm_token');
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
    final observer = _lifecycleObserver;
    if (observer != null) {
      WidgetsBinding.instance.removeObserver(observer);
      _lifecycleObserver = null;
    }
    await _authSub?.cancel();
    await _tokenRefreshSub?.cancel();
    await _stopOnlineAnnouncementFallback();
  }
}

class _LifecycleObserver with WidgetsBindingObserver {
  _LifecycleObserver(this._service);

  final PushNotificationsService _service;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_service._catchUpMissedNotificationsIfNeeded());
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_service._touchLastSeenAt());
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }
}

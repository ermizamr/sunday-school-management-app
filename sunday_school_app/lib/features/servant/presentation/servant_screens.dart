import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:sunday_school_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/auth_providers.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/refresh/app_refresh_scope.dart';
import '../../../core/refresh/app_refresh_configurator.dart';
import '../../../core/dates/ethiopian_date_formatter.dart';
import '../../../core/promotions/promotion_criteria_set.dart';
import '../../../core/push/push_notifications_service.dart';
import 'attendance/servant_attendance_home_screen.dart';

class ServantShell extends StatelessWidget {
  const ServantShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFD97706), // amber-600
        unselectedItemColor: const Color(0xFF64748B), // slate-500
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: l10n.navHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_month_rounded),
            label: l10n.navAttendance,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.auto_stories_rounded),
            label: l10n.navGrades,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.forum_rounded),
            label: l10n.navCommunication,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline_rounded),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}

class ServantLoginScreen extends ConsumerStatefulWidget {
  const ServantLoginScreen({super.key});

  @override
  ConsumerState<ServantLoginScreen> createState() => _ServantLoginScreenState();
}

class _ServantLoginScreenState extends ConsumerState<ServantLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      String? role;
      try {
        role = (await authRepository.fetchCurrentUserRole())
            ?.trim()
            .toLowerCase();
      } catch (_) {
        role = null;
      }

      final allowed = role == 'servant' || role == 'admin';
      if (!allowed) {
        try {
          await authRepository.signOut();
        } catch (_) {}
        if (mounted) {
          setState(() {
            _error = role == null
                ? l10n.authRoleVerificationFailed
                : l10n.authRoleMismatchServant;
          });
        }
        return;
      }

      if (mounted) {
        context.go('/servant/dashboard');
      }
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _error = l10n.authLoginFailedGeneric;
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFEF3C7), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextButton.icon(
                      onPressed: () => context.go('/'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      label: Text(
                        l10n.commonBackToHome,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14374151),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFFD97706),
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.authServantLoginTitle,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.authLoginSubtitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  l10n.authEmailLabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _IconTextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  hintText: l10n.authEmailHint,
                                  icon: Icons.person_rounded,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.authEmailRequiredError;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.authPasswordLabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _IconTextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  hintText: l10n.authPasswordHint,
                                  icon: Icons.lock_rounded,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.authPasswordRequiredError;
                                    }
                                    if (value.length < 6) {
                                      return l10n.authPasswordMinLengthError(6);
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                if (_error != null) ...[
                                  Text(
                                    _error!,
                                    style: TextStyle(
                                      color: colorScheme.error,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                SizedBox(
                                  height: 48,
                                  child: FilledButton.icon(
                                    onPressed: _submitting ? null : _submit,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFD97706),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    icon: _submitting
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                    label: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(l10n.authLoginButton),
                                        if (!_submitting) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 20,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.center,
                            child: TextButton(
                              onPressed: () {
                                showDialog<void>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      l10n.authForgotPasswordDialogTitle,
                                    ),
                                    content: Text(
                                      l10n.authForgotPasswordDialogBody,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: Text(l10n.commonOk),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFF59E0B),
                              ),
                              child: Text(
                                l10n.authForgotPassword,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconTextField extends StatelessWidget {
  const _IconTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 14,
        ),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF9CA3AF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Color(0xFFF59E0B), width: 2),
        ),
      ),
    );
  }
}

class ServantDashboardScreen extends StatefulWidget {
  const ServantDashboardScreen({super.key});

  @override
  State<ServantDashboardScreen> createState() => _ServantDashboardScreenState();

  // Minimal stand-in for FunctionResponse so we can call the Edge Function
  // with explicit headers and isolate JWT issues.
  Future<({int status, dynamic data})> _invokeAdminCreateUserViaHttp({
    required SupabaseClient client,
    required Map<String, dynamic> body,
  }) async {
    final session = client.auth.currentSession;
    final accessToken = session?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw const _AuthRequiredException();
    }

    final uri = Uri.parse(
      '${SupabaseConfig.url}/functions/v1/admin-create-user',
    );

    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'apikey': SupabaseConfig.anonKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    dynamic data;
    try {
      data = res.body.isEmpty ? null : jsonDecode(res.body);
    } catch (_) {
      data = {'raw': res.body};
    }

    return (status: res.statusCode, data: data);
  }

  String _accessTokenDebugSummary(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return 'jwtParts=${parts.length}';

      Map<String, dynamic> decodeJsonPart(String part) {
        final bytes = base64Url.decode(base64Url.normalize(part));
        final obj = jsonDecode(utf8.decode(bytes));
        if (obj is Map) return Map<String, dynamic>.from(obj);
        return const <String, dynamic>{};
      }

      final header = decodeJsonPart(parts[0]);
      final payload = decodeJsonPart(parts[1]);

      final alg = header['alg'];
      final aud = payload['aud'];
      final iss = payload['iss'];
      final sub = payload['sub'];
      final role = payload['role'];
      final iat = payload['iat'];

      String? issHost;
      if (iss is String) {
        try {
          issHost = Uri.parse(iss).host;
        } catch (_) {
          issHost = iss;
        }
      }

      String? expIso;
      final exp = payload['exp'];
      if (exp is int) {
        expIso = DateTime.fromMillisecondsSinceEpoch(
          exp * 1000,
          isUtc: true,
        ).toIso8601String();
      }

      int? ttlSec;
      if (exp is int && iat is int) {
        ttlSec = exp - iat;
      }

      return 'alg=$alg aud=$aud issHost=$issHost iat=$iat exp=$expIso ttlSec=$ttlSec sub=$sub role=$role';
    } catch (e) {
      return 'jwtSummaryError=${e.runtimeType}';
    }
  }

  String _generateAcademicId(Random random) {
    final fourDigits = random.nextInt(9000) + 1000;
    final ethYear = EthiopianCalendar.fromGregorianDateTime(
      DateTime.now(),
    ).year;
    final yy = (ethYear % 100).toString().padLeft(2, '0');
    return '${fourDigits.toString().padLeft(4, '0')}/$yy';
  }

  bool _looksLikeAcademicIdConflict(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('academic') &&
            (msg.contains('exists') || msg.contains('duplicate')) ||
        msg.contains('duplicate key') ||
        msg.contains('already registered') ||
        msg.contains('already exists');
  }

  bool _looksLikeInvalidJwt(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('invalid jwt') ||
        (msg.contains('jwt') && msg.contains('invalid'));
  }

  void _scheduleAuthResetAndRedirectToServantLogin(BuildContext rootContext) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final client = SupabaseClientManager.instance.client;
      try {
        await client.auth.signOut();
      } catch (_) {}

      if (!rootContext.mounted) return;
      final l10n = AppLocalizations.of(rootContext);
      ScaffoldMessenger.of(
        rootContext,
      ).showSnackBar(SnackBar(content: Text(l10n.authLoginFailedGeneric)));
      GoRouter.of(rootContext).go('/servant/login');
    });
  }

  Future<void> _ensureSignedInAndFreshToken(SupabaseClient client) async {
    // If the user is signed out, Supabase will call functions using the anon key
    // which then fails server-side with "invalid JWT".
    if (client.auth.currentSession == null || client.auth.currentUser == null) {
      throw const _AuthRequiredException();
    }

    bool isTokenExpired(String token) {
      try {
        final parts = token.split('.');
        if (parts.length != 3) return true;
        final bytes = base64Url.decode(base64Url.normalize(parts[1]));
        final obj = jsonDecode(utf8.decode(bytes));
        if (obj is! Map) return true;
        final exp = obj['exp'];
        if (exp is! int) return true;
        final expTime = DateTime.fromMillisecondsSinceEpoch(
          exp * 1000,
          isUtc: true,
        );
        // Small grace window to avoid edge-of-expiry flakiness.
        return expTime.isBefore(
          DateTime.now().toUtc().add(const Duration(seconds: 15)),
        );
      } catch (_) {
        return true;
      }
    }

    try {
      final before = client.auth.currentSession;
      final beforeToken = before?.accessToken;
      final beforeExp = beforeToken == null
          ? null
          : _accessTokenDebugSummary(beforeToken);

      final res = await client.auth.refreshSession();

      final after = res.session ?? client.auth.currentSession;
      final afterToken = after?.accessToken;
      final afterExp = afterToken == null
          ? null
          : _accessTokenDebugSummary(afterToken);

      if (afterToken == null || afterToken.isEmpty) {
        throw const _AuthRequiredException();
      }

      // If the refresh didn't rotate an already-expired token, treat auth as broken.
      if (isTokenExpired(afterToken)) {
        // Helpful diagnostic without leaking tokens.
        print(
          'RegisterStudent: token still expired after refresh (before=$beforeExp, after=$afterExp)',
        );
        throw const _AuthRequiredException();
      }

      // If token looks unchanged and was expired, force relogin.
      if (beforeToken != null &&
          beforeToken == afterToken &&
          isTokenExpired(beforeToken)) {
        print('RegisterStudent: refreshSession did not rotate expired token');
        throw const _AuthRequiredException();
      }
    } catch (e) {
      if (_looksLikeInvalidJwt(e)) throw const _AuthRequiredException();
      // Best-effort; still allow call if session exists.
    }

    if (client.auth.currentSession == null || client.auth.currentUser == null) {
      throw const _AuthRequiredException();
    }
  }

  Future<Map<String, dynamic>> _registerStudentWithRetry({
    required String name,
    required String gradeId,
  }) async {
    final client = SupabaseClientManager.instance.client;
    await _ensureSignedInAndFreshToken(client);

    final random = Random.secure();
    Object? lastError;

    for (var attempt = 0; attempt < 5; attempt++) {
      final academicId = _generateAcademicId(random);
      try {
        var authRetried = false;
        late ({int status, dynamic data}) response;
        while (true) {
          await _ensureSignedInAndFreshToken(client);

          final session = client.auth.currentSession;
          final accessToken = session?.accessToken;
          if (accessToken == null || accessToken.isEmpty) {
            throw const _AuthRequiredException();
          }

          // Use print (not debugPrint) so it always shows up in flutter run.
          print(
            'RegisterStudent: invoking admin-create-user '
            '(tokenLen=${accessToken.length}, expiresAt=${session?.expiresAt}, uid=${client.auth.currentUser?.id}, ${_accessTokenDebugSummary(accessToken)})',
          );

          try {
            response = await _invokeAdminCreateUserViaHttp(
              client: client,
              body: {
                'name': name,
                'grade_id': gradeId,
                'academic_id': academicId,
                'role': 'student',
                'password': academicId,
              },
            );
          } catch (e) {
            print(
              'RegisterStudent: admin-create-user HTTP invoke error '
              '(type=${e.runtimeType}, msg=$e)',
            );
            rethrow;
          }

          if (response.status == 401) {
            print(
              'RegisterStudent: admin-create-user HTTP 401 '
              '(body=${response.data})',
            );
            try {
              final userRes = await client.auth.getUser();
              print(
                'RegisterStudent: auth.getUser() after 401 '
                '(ok=${userRes.user != null}, userId=${userRes.user?.id})',
              );
            } catch (e) {
              print(
                'RegisterStudent: auth.getUser() after 401 threw '
                '(type=${e.runtimeType}, msg=$e)',
              );
            }
            if (authRetried) {
              throw const _AuthRequiredException();
            }
            authRetried = true;
            await _ensureSignedInAndFreshToken(client);
            continue;
          }

          break;
        }

        if (response.status != 200) {
          final data = response.data;
          print(
            'RegisterStudent: admin-create-user HTTP non-200 '
            '(status=${response.status}, body=$data)',
          );
          throw Exception(
            data is Map && data['error'] != null
                ? data['error'].toString()
                : 'Request failed (${response.status})',
          );
        }

        final data = response.data;
        if (data is Map) {
          final m = Map<String, dynamic>.from(data);
          m['academic_id'] ??= academicId;
          return m;
        }
        throw Exception('Unexpected response from server');
      } catch (e) {
        lastError = e;
        if (!_looksLikeAcademicIdConflict(e)) rethrow;
      }
    }

    throw Exception(lastError?.toString() ?? 'Failed to register student');
  }

  Future<void> _showRegisterStudentDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final client = SupabaseClientManager.instance.client;

    // If not signed in, redirect to servant login early.
    if (client.auth.currentSession == null || client.auth.currentUser == null) {
      if (context.mounted) {
        _scheduleAuthResetAndRedirectToServantLogin(context);
      }
      return;
    }

    // Ensure we have a valid access token before any DB reads.
    // Otherwise Supabase may query using an expired/anon context, and RLS blocks
    // grade reads which makes registration look "broken".
    try {
      await _ensureSignedInAndFreshToken(client);
    } catch (_) {
      if (context.mounted) {
        _scheduleAuthResetAndRedirectToServantLogin(context);
      }
      return;
    }

    List<_RegisterStudentGrade> grades = const [];
    String? gradesLoadError;
    try {
      dynamic rows;
      try {
        // Prefer sort_order if it exists.
        rows = await client
            .from('grades')
            .select('id, name, code')
            .order('sort_order')
            .order('name');
      } catch (e) {
        // Fallback when sort_order doesn't exist (or isn't selectable by RLS).
        debugPrint('RegisterStudent: grades query w/ sort_order failed: $e');
        rows = await client
            .from('grades')
            .select('id, name, code')
            .order('name');
      }

      final parsed = <_RegisterStudentGrade>[];
      for (final row in rows as List) {
        final m = row as Map;
        final id = (m['id'] ?? '').toString().trim();
        final displayName = (m['name'] ?? m['code'] ?? m['id'] ?? '')
            .toString()
            .trim();
        if (id.isNotEmpty && displayName.isNotEmpty) {
          parsed.add(_RegisterStudentGrade(id: id, name: displayName));
        }
      }
      grades = parsed;
    } catch (e) {
      debugPrint('RegisterStudent: grades load failed: $e');
      grades = const [];
      gradesLoadError = e.toString();
    }

    if (!context.mounted) return;

    final nameController = TextEditingController();
    _RegisterStudentGrade? selectedGrade = grades.isNotEmpty
        ? grades.first
        : null;
    bool submitting = false;
    String? error;

    Future<void> submit(
      BuildContext dialogContext,
      StateSetter setState,
    ) async {
      final name = nameController.text.trim();
      if (name.isEmpty) {
        if (!dialogContext.mounted) return;
        setState(() {
          error = l10n.servantRegisterStudentNameRequired;
        });
        return;
      }
      final grade = selectedGrade;
      if (grade == null) {
        if (!dialogContext.mounted) return;
        setState(() {
          error = l10n.servantRegisterStudentGradeRequired;
        });
        return;
      }

      if (!dialogContext.mounted) return;
      setState(() {
        submitting = true;
        error = null;
      });

      try {
        final result = await _registerStudentWithRetry(
          name: name,
          gradeId: grade.id,
        );
        if (!dialogContext.mounted) return;

        final academicId = (result['academic_id'] ?? '').toString();
        Navigator.of(dialogContext).pop();

        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.servantRegisterStudentSuccessTitle),
            content: Text(
              l10n.servantRegisterStudentSuccessMessage(academicId),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.commonOk),
              ),
            ],
          ),
        );
      } catch (e) {
        if (e is _AuthRequiredException) {
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
          if (!context.mounted) return;
          _scheduleAuthResetAndRedirectToServantLogin(context);
          return;
        }

        if (!dialogContext.mounted) return;
        setState(() {
          submitting = false;
          error = e.toString();
        });
      }
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.servantRegisterStudentTitle),
              content: SizedBox(
                width: 420,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: l10n.servantRegisterStudentFullNameLabel,
                            hintText: l10n.servantRegisterStudentFullNameHint,
                          ),
                          enabled: !submitting,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<_RegisterStudentGrade>(
                          initialValue: selectedGrade,
                          items: [
                            for (final g in grades)
                              DropdownMenuItem(value: g, child: Text(g.name)),
                          ],
                          onChanged: (submitting || grades.isEmpty)
                              ? null
                              : (value) {
                                  setState(() {
                                    selectedGrade = value;
                                  });
                                },
                          decoration: InputDecoration(
                            labelText: l10n.servantRegisterStudentGradeLabel,
                          ),
                        ),
                        if (grades.isEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'ክፍሎች አልተገኙም።',
                            style: TextStyle(color: Colors.red),
                          ),
                          if (gradesLoadError != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              gradesLoadError,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ],
                        if (error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            error!,
                            maxLines: 6,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text(l10n.commonCancel),
                ),
                FilledButton(
                  onPressed: submitting
                      ? null
                      : () => submit(context, setState),
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.servantRegisterStudentSubmit),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
  }

  Widget _buildDashboardScaffold(
    BuildContext context, {
    required bool loading,
    required String? error,
    required _ServantDashboardStats? stats,
    required VoidCallback onRetry,
  }) {
    final l10n = AppLocalizations.of(context);

    final totalStudents = stats?.totalStudents ?? 0;
    final avgAttendance = stats?.avgAttendancePercent ?? 0;
    final pendingQuestions = stats?.pendingQuestions ?? 0;
    final pendingComplaints = stats?.pendingComplaints ?? 0;

    final classSizeText = loading ? '—' : '$totalStudents';
    final avgAttendanceText = loading ? '—' : '$avgAttendance%';
    final pendingTotalText = loading
        ? '—'
        : '${pendingQuestions + pendingComplaints}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // slate-50
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF59E0B), // amber-500
                    Color(0xFFD97706), // amber-600
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.servantDashboardTitle,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.servantDashboardSubtitle,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFFFDE68A), // amber-200
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Class summary card
                    SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14374151),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.groups_rounded,
                                  color: Color(0xFFD97706),
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.servantTotalStudents,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    classSizeText,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.servantDashboardAvgAttendanceLabel,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        avgAttendanceText,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.servantDashboardPendingItemsLabel,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        pendingTotalText,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick actions
                    Text(
                      l10n.servantDashboardQuickActionsTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        _ServantQuickActionButton(
                          background: const Color(0xFF0EA5E9),
                          foreground: Colors.white,
                          iconBackground: Colors.white24,
                          icon: Icons.fact_check_rounded,
                          title: l10n.servantDashboardMarkAttendanceTitle,
                          subtitle: l10n.servantDashboardMarkAttendanceSubtitle,
                          onTap: () =>
                              GoRouter.of(context).go('/servant/attendance'),
                        ),
                        const SizedBox(height: 10),
                        _ServantQuickActionButton(
                          background: Colors.white,
                          foreground: const Color(0xFF0F172A),
                          iconBackground: const Color(0xFFFEF3C7),
                          icon: Icons.menu_book_rounded,
                          title: l10n.servantDashboardAddGradesTitle,
                          subtitle: l10n.servantDashboardAddGradesSubtitle,
                          borderColor: const Color(0xFFE2E8F0),
                          onTap: () =>
                              GoRouter.of(context).go('/servant/grades'),
                        ),
                        const SizedBox(height: 10),
                        _ServantQuickActionButton(
                          background: Colors.white,
                          foreground: const Color(0xFF0F172A),
                          iconBackground: const Color(0xFFE0F2FE),
                          icon: Icons.person_add_alt_1_rounded,
                          title: l10n.servantRegisterStudentQuickActionTitle,
                          subtitle:
                              l10n.servantRegisterStudentQuickActionSubtitle,
                          borderColor: const Color(0xFFE2E8F0),
                          onTap: () => _showRegisterStudentDialog(context),
                        ),
                        const SizedBox(height: 10),
                        _ServantQuickActionButton(
                          background: const Color(0xFF0284C7),
                          foreground: Colors.white,
                          iconBackground: Colors.white24,
                          icon: Icons.insights_rounded,
                          title: l10n.servantAnalyticsTitle,
                          subtitle: l10n.servantDashboardGradeAnalyticsSubtitle,
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Color(0xFF0EA5E9), Color(0xFF0369A1)],
                          ),
                          onTap: () =>
                              GoRouter.of(context).go('/servant/analytics'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Today schedule
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                            child: Text(
                              l10n.servantDashboardTodayScheduleTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          _ScheduleRow(
                            iconBg: const Color(0xFFE0F2FE),
                            iconColor: const Color(0xFF0284C7),
                            title: l10n.servantDashboardSundaySchoolClassTitle,
                            time: l10n.servantDashboardSundaySchoolClassTime,
                          ),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          _ScheduleRow(
                            iconBg: const Color(0xFFFEF3C7),
                            iconColor: const Color(0xFFD97706),
                            title: l10n.servantDashboardBibleStudyReviewTitle,
                            time: l10n.servantDashboardBibleStudyReviewTime,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    if (error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              error,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF991B1B),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: onRetry,
                                child: Text(l10n.commonRetry),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Pending communication alert
                    if (!loading &&
                        (pendingQuestions > 0 || pendingComplaints > 0))
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB), // amber-50
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFFDE68A), // amber-200
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.chat_bubble_rounded,
                              color: Color(0xFFD97706),
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.servantDashboardPendingMessage(
                                      pendingQuestions,
                                      pendingComplaints,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF92400E),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => GoRouter.of(
                                context,
                              ).go('/servant/communication'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF92400E),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                              ),
                              child: Text(
                                l10n.servantDashboardViewButton,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServantDashboardStats {
  const _ServantDashboardStats({
    required this.totalStudents,
    required this.avgAttendancePercent,
    required this.pendingQuestions,
    required this.pendingComplaints,
  });

  final int totalStudents;
  final int avgAttendancePercent;
  final int pendingQuestions;
  final int pendingComplaints;
}

class _ServantDashboardScreenState extends State<ServantDashboardScreen> {
  bool _loading = true;
  String? _error;
  _ServantDashboardStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStatsFromBackend();
  }

  Future<String?> _activeAcademicYearId(SupabaseClient client) async {
    try {
      final id = await client.rpc('active_academic_year_id');
      final asString = id?.toString();
      if (asString != null && asString.isNotEmpty) return asString;
    } catch (_) {}

    try {
      final row = await client
          .from('academic_years')
          .select('id')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return (row as Map?)?['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadStatsFromBackend() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = SupabaseClientManager.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw StateError('Not signed in');
      }

      final profile = await client
          .from('profiles')
          .select('grade_id')
          .eq('id', userId)
          .maybeSingle();
      final gradeId = (profile as Map?)?['grade_id']?.toString();
      if (gradeId == null || gradeId.isEmpty) {
        throw StateError('Missing grade assignment');
      }

      final academicYearId = await _activeAcademicYearId(client);
      if (academicYearId == null || academicYearId.isEmpty) {
        throw StateError('Missing academic year');
      }

      var totalStudents = 0;
      try {
        final rows = await client
            .from('profiles')
            .select('id')
            .eq('role', 'student')
            .eq('grade_id', gradeId);
        totalStudents = (rows as List).length;
      } catch (_) {}

      var pendingQuestions = 0;
      try {
        final rows = await client
            .from('questions')
            .select('id')
            .eq('grade_id', gradeId)
            .eq('academic_year_id', academicYearId)
            .eq('answered', false);
        pendingQuestions = (rows as List).length;
      } catch (_) {}

      var pendingComplaints = 0;
      try {
        final rows = await client
            .from('complaints')
            .select('id')
            .eq('grade_id', gradeId)
            .eq('academic_year_id', academicYearId)
            .inFilter('status', const ['pending', 'in_review']);
        pendingComplaints = (rows as List).length;
      } catch (_) {}

      var avgAttendancePercent = 0;
      try {
        final sessions = await client
            .from('attendance_sessions')
            .select('id')
            .eq('grade_id', gradeId)
            .eq('academic_year_id', academicYearId);

        final sessionIds = (sessions as List)
            .map((r) => (r as Map)['id']?.toString())
            .whereType<String>()
            .toList(growable: false);

        if (sessionIds.isNotEmpty) {
          final records = await client
              .from('attendance_records')
              .select('status')
              .inFilter('session_id', sessionIds);

          var total = 0;
          var presentLate = 0;
          for (final r in (records as List)) {
            final status = (r as Map)['status']?.toString();
            if (status == null) continue;
            if (status == 'permission') continue;
            total++;
            if (status == 'present' || status == 'late') {
              presentLate++;
            }
          }

          avgAttendancePercent = total == 0
              ? 0
              : ((100.0 * presentLate) / total).round();
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _stats = _ServantDashboardStats(
          totalStudents: totalStudents,
          avgAttendancePercent: avgAttendancePercent.clamp(0, 100),
          pendingQuestions: pendingQuestions,
          pendingComplaints: pendingComplaints,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget._buildDashboardScaffold(
      context,
      loading: _loading,
      error: _error,
      stats: _stats,
      onRetry: _loadStatsFromBackend,
    );
  }
}

class _RegisterStudentGrade {
  const _RegisterStudentGrade({required this.id, required this.name});
  final String id;
  final String name;

  @override
  String toString() => name;
}

class _AuthRequiredException implements Exception {
  const _AuthRequiredException();
}

class _ServantQuickActionButton extends StatelessWidget {
  const _ServantQuickActionButton({
    required this.background,
    required this.foreground,
    required this.iconBackground,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.borderColor,
    this.gradient,
  });

  final Color background;
  final Color foreground;
  final Color iconBackground;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? borderColor;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: gradient == null ? background : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1.5)
              : null,
          boxShadow: const [
            BoxShadow(
              color: Color(0x14374151),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: foreground, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: foreground.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.time,
  });

  final Color iconBg;
  final Color iconColor;
  final String title;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ServantAttendanceScreen extends StatelessWidget {
  const ServantAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServantAttendanceHomeScreen();
  }
}

class ServantGradesScreen extends StatefulWidget {
  const ServantGradesScreen({super.key});

  @override
  State<ServantGradesScreen> createState() => _ServantGradesScreenState();
}

enum _ServantGradesView { list, add, edit, addSubject, missing }

class _ServantGradesSubject {
  const _ServantGradesSubject({required this.id, required this.name});
  final String id;
  final String name;
}

class _ServantGradesStudent {
  const _ServantGradesStudent({required this.id, required this.name});
  final String id;
  final String name;
}

class _ServantGradeEntry {
  const _ServantGradeEntry({
    required this.id,
    required this.subjectId,
    required this.gradeType,
    required this.maxScore,
    required this.date,
    this.weight,
    required this.scores,
  });

  final String id;
  final String subjectId;
  final String gradeType;
  final int maxScore;
  final int? weight;
  final DateTime date;
  final Map<String, double?> scores;
}

class _ServantGradesScreenState extends State<ServantGradesScreen> {
  Future<void> _loadSubjects() async {
    setState(() {
      _loadingSubjects = true;
      _subjectsError = null;
    });
    try {
      final client = SupabaseClientManager.instance.client;
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Not signed in');

      final profile = await client
          .from('profiles')
          .select('grade_id')
          .eq('id', user.id)
          .maybeSingle();
      final gradeId = profile?['grade_id']?.toString();
      if (gradeId == null || gradeId.isEmpty) {
        throw Exception('Servant is not assigned to a grade');
      }

      _myGradeId = gradeId;

      final data = await client
          .from('subjects')
          .select('id, name')
          .eq('grade_id', gradeId)
          .eq('active', true)
          .order('name');
      final subjects = <_ServantGradesSubject>[];
      for (final s in data) {
        final m = s as Map;
        final id = m['id']?.toString();
        final name = m['name']?.toString();
        if (id != null && name != null) {
          subjects.add(_ServantGradesSubject(id: id, name: name));
        }
      }
      setState(() {
        _subjects = subjects;
        _selectedSubject = subjects.isNotEmpty ? subjects.first : null;
        _loadingSubjects = false;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _subjectsError = l10n.servantGradesLoadSubjectsFailed;
        _loadingSubjects = false;
      });
    }
  }

  // UI and logic state
  _ServantGradeEntry? _selectedEntry;
  String? _myGradeId;
  String? _academicYearId;
  String? _academicYearName;
  String? _academicYearStatus;
  bool _loadingLockState = true;
  bool _isLocked = false;
  String? _lockMessage;
  PromotionCriteriaSet _criteria = PromotionCriteriaSet.defaults;
  bool _loadingCriteria = false;
  bool _showWeightedGrades = false;
  String _weightedSearch = '';
  String? _viewingScoresEntryId;
  final Map<String, String> _entryScoreSearch = {};
  final _assessmentNameController = TextEditingController();
  final _maxScoreController = TextEditingController();
  final _weightController = TextEditingController();
  DateTime? _assessmentDate;
  final Map<String, TextEditingController> _studentScoreControllers = {};
  String _studentScoresSearch = '';
  int _studentScoresPage = 0;
  final _subjectNameController = TextEditingController();
  List<_ServantGradesSubject> _subjects = [];
  _ServantGradesSubject? _selectedSubject;
  bool _loadingSubjects = true;
  String? _subjectsError;
  // Students state
  List<_ServantGradesStudent> _students = [];
  bool _loadingStudents = true;
  String? _studentsError;

  // Grade entries state
  List<_ServantGradeEntry> _gradeEntries = [];
  bool _loadingGradeEntries = true;
  String? _gradeEntriesError;
  // Fetch students for the servant's grade from Supabase
  Future<void> _loadStudents() async {
    setState(() {
      _loadingStudents = true;
      _studentsError = null;
    });
    try {
      final client = SupabaseClientManager.instance.client;
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Not signed in');
      final profile = await client
          .from('profiles')
          .select('grade_id')
          .eq('id', user.id)
          .maybeSingle();
      final gradeId = profile?['grade_id']?.toString();
      if (gradeId == null || gradeId.isEmpty) {
        throw Exception('Servant is not assigned to a grade');
      }

      _myGradeId = gradeId;

      final data = await client
          .from('profiles')
          .select('id, name')
          .eq('role', 'student')
          .eq('grade_id', gradeId)
          .order('name');
      final students = <_ServantGradesStudent>[];
      for (final s in data) {
        final m = s as Map;
        final id = m['id']?.toString();
        final name = m['name']?.toString();
        if (id != null && name != null) {
          students.add(_ServantGradesStudent(id: id, name: name));
        }
      }
      setState(() {
        _students = students;
        _loadingStudents = false;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _studentsError = l10n.servantGradesLoadStudentsFailed;
        _loadingStudents = false;
      });
    }
  }

  // Fetch grade entries for the servant's grade from Supabase
  Future<void> _loadGradeEntries() async {
    setState(() {
      _loadingGradeEntries = true;
      _gradeEntriesError = null;
    });
    try {
      final client = SupabaseClientManager.instance.client;
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Not signed in');

      final academicYear = await client
          .from('academic_years')
          .select('id')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final academicYearId =
          (academicYear?['id'] as String?) ?? _academicYearId;
      if (academicYearId == null || academicYearId.isEmpty) {
        throw Exception('No active academic year found');
      }

      final profile = await client
          .from('profiles')
          .select('grade_id')
          .eq('id', user.id)
          .maybeSingle();
      final gradeId = profile?['grade_id']?.toString();
      if (gradeId == null || gradeId.isEmpty) {
        throw Exception('Servant is not assigned to a grade');
      }

      _myGradeId = gradeId;

      final assessmentsRows = await client
          .from('assessments')
          .select(
            'id, subject_id, grade_type, max_score, weight, assessment_date',
          )
          .eq('academic_year_id', academicYearId)
          .eq('grade_id', gradeId)
          .order('assessment_date', ascending: false);

      final assessmentIds = <String>[];
      for (final row in assessmentsRows) {
        final id = (row['id'] as String?);
        if (id != null && id.isNotEmpty) assessmentIds.add(id);
      }

      final scoresByAssessment = <String, Map<String, double?>>{};
      if (assessmentIds.isNotEmpty) {
        final scoreRows = await client
            .from('assessment_scores')
            .select('assessment_id, student_id, score')
            .inFilter('assessment_id', assessmentIds);

        for (final row in scoreRows) {
          final assessmentId = row['assessment_id'] as String?;
          final studentId = row['student_id'] as String?;
          if (assessmentId == null || studentId == null) continue;
          final score = (row['score'] as num?)?.toDouble();

          final map = scoresByAssessment.putIfAbsent(
            assessmentId,
            () => <String, double?>{},
          );
          map[studentId] = score;
        }
      }

      final entries = <_ServantGradeEntry>[];
      for (final row in assessmentsRows) {
        final id = row['id'] as String?;
        final subjectId = row['subject_id'] as String?;
        final gradeType =
            (row['grade_type'] as String?) ??
            AppLocalizations.of(context).servantGradesDefaultAssessmentType;
        final maxScoreNum = row['max_score'] as num?;
        final weightNum = row['weight'] as num?;
        final dateStr = row['assessment_date'] as String?;

        final date = dateStr == null ? null : DateTime.tryParse(dateStr);
        if (id == null ||
            subjectId == null ||
            maxScoreNum == null ||
            date == null) {
          continue;
        }

        entries.add(
          _ServantGradeEntry(
            id: id,
            subjectId: subjectId,
            gradeType: gradeType,
            maxScore: maxScoreNum.toInt(),
            weight: weightNum?.toInt(),
            date: date,
            scores: scoresByAssessment[id] ?? <String, double?>{},
          ),
        );
      }

      setState(() {
        _gradeEntries = entries;
        _loadingGradeEntries = false;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _gradeEntriesError = l10n.servantGradesLoadGradeEntriesFailed;
        _loadingGradeEntries = false;
      });
    }
  }

  _ServantGradesView _view = _ServantGradesView.list;

  static const int _scoresPageSize = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadLockState();
      _loadPromotionCriteria();
      _loadSubjects();
      _loadStudents();
      _loadGradeEntries();
    });
  }

  Future<void> _loadPromotionCriteria() async {
    if (_loadingCriteria) return;
    setState(() {
      _loadingCriteria = true;
    });

    try {
      final client = Supabase.instance.client;
      final repo = PromotionCriteriaRepository(client);
      final criteria = await repo.fetchForCurrentUserActiveYear();
      if (!mounted) return;
      if (criteria != null) {
        setState(() {
          _criteria = criteria;
        });
      }
    } catch (_) {
      // Keep defaults on any error.
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingCriteria = false;
      });
    }
  }

  @override
  void dispose() {
    _assessmentNameController.dispose();
    _maxScoreController.dispose();
    _weightController.dispose();
    _subjectNameController.dispose();
    for (final c in _studentScoreControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadLockState() async {
    setState(() {
      _loadingLockState = true;
      _lockMessage = null;
    });

    final supabase = SupabaseClientManager.instance.client;
    final l10n = AppLocalizations.of(context);

    try {
      // Academic year (prefer active; fallback to any latest row if active not found).
      final activeYear = await supabase
          .from('academic_years')
          .select('id,name,status')
          .eq('status', 'active')
          .maybeSingle();

      Map<String, dynamic>? year = activeYear;
      year ??= await supabase
          .from('academic_years')
          .select('id,name,status')
          .order('start_date', ascending: false)
          .limit(1)
          .maybeSingle();

      _academicYearId = year?['id'] as String?;
      _academicYearName = year?['name'] as String?;
      _academicYearStatus = year?['status'] as String?;

      final isYearActive = _academicYearStatus == 'active';

      // Global feature flag (optional table; default enabled).
      var globalEnabled = true;
      try {
        final flag = await supabase
            .from('app_feature_flags')
            .select('enabled')
            .eq('key', 'grades.editing.enabled')
            .maybeSingle();
        if (flag != null && flag['enabled'] != null) {
          globalEnabled = flag['enabled'] as bool;
        }
      } catch (_) {
        // Ignore if the feature flag table is not yet deployed.
      }

      // Per-year override (auto/locked/unlocked). Optional table; default auto.
      var yearMode = 'auto';
      try {
        final yearId = _academicYearId;
        if (yearId != null) {
          final policy = await supabase
              .from('academic_year_policies')
              .select('grades_edit_mode')
              .eq('academic_year_id', yearId)
              .maybeSingle();
          if (policy != null && policy['grades_edit_mode'] != null) {
            yearMode = policy['grades_edit_mode'] as String;
          }
        }
      } catch (_) {
        // Ignore if the policies table is not yet deployed.
      }

      bool editable;
      if (!globalEnabled) {
        editable = false;
        _lockMessage = l10n.servantGradesLockedByAdminSettings;
      } else if (yearMode == 'locked') {
        editable = false;
      } else if (yearMode == 'unlocked') {
        editable = true;
      } else {
        editable = isYearActive;
      }

      if (!editable && _lockMessage == null) {
        final yearName =
            _academicYearName ?? l10n.servantGradesThisAcademicYear;
        if (!isYearActive) {
          _lockMessage = l10n.servantGradesAcademicYearEndedLocked(yearName);
        } else {
          _lockMessage = l10n.servantGradesLocked;
        }
      }

      setState(() {
        _isLocked = !editable;
      });
    } catch (_) {
      // If anything goes wrong (missing columns/tables), do not block grading UI.
      setState(() {
        _isLocked = false;
        _lockMessage = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingLockState = false;
        });
      }
    }
  }

  List<_ServantGradeEntry> _entriesForSelectedSubject() {
    if (_selectedSubject == null) return [];
    final entries = _gradeEntries
        .where((e) => e.subjectId == _selectedSubject!.id)
        .toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  int _totalWeightForSubject(String subjectId) {
    return _gradeEntries
        .where((e) => e.subjectId == subjectId)
        .fold<int>(0, (sum, e) => sum + (e.weight ?? 0));
  }

  int? _calculateSubjectAverage(String studentId, String subjectId) {
    final entries = _gradeEntries.where((e) => e.subjectId == subjectId);
    if (entries.isEmpty) return 0;

    final allHaveScores = entries.every((e) {
      final score = e.scores[studentId];
      return score != null;
    });
    if (!allHaveScores) return null;

    final totalWeight = entries.fold<int>(0, (sum, e) => sum + (e.weight ?? 0));
    if (totalWeight > 0) {
      var weighted = 0.0;
      for (final entry in entries) {
        final score = entry.scores[studentId];
        if (score == null) continue;
        final pct = (score / entry.maxScore) * 100;
        weighted += pct * ((entry.weight ?? 0) / totalWeight);
      }
      return weighted.round();
    }

    var totalPct = 0.0;
    var count = 0;
    for (final entry in entries) {
      final score = entry.scores[studentId];
      if (score == null) continue;
      totalPct += (score / entry.maxScore) * 100;
      count++;
    }
    if (count == 0) return 0;
    return (totalPct / count).round();
  }

  int _classAverageForEntry(_ServantGradeEntry entry) {
    final scored = entry.scores.values.whereType<double>().toList();
    if (scored.isEmpty) return 0;
    final avgPct =
        scored.map((s) => (s / entry.maxScore) * 100).reduce((a, b) => a + b) /
        scored.length;
    return avgPct.round();
  }

  Color _gradeTextColor(int grade) {
    final c = _criteria.classify(grade.toDouble());
    switch (c) {
      case GradeClassification.excellent:
        return const Color(0xFF16A34A); // green-600
      case GradeClassification.veryGood:
      case GradeClassification.good:
        return const Color(0xFF0284C7); // sky-600
      case GradeClassification.enough:
        return const Color(0xFFD97706); // amber-600
      case GradeClassification.critical:
        return const Color(0xFFDC2626); // red-600
    }
  }

  Color _gradeBarColor(int grade) {
    final c = _criteria.classify(grade.toDouble());
    switch (c) {
      case GradeClassification.excellent:
        return const Color(0xFF22C55E); // green-500
      case GradeClassification.veryGood:
      case GradeClassification.good:
        return const Color(0xFF0EA5E9); // sky-500
      case GradeClassification.enough:
        return const Color(0xFFFBBF24); // amber-500
      case GradeClassification.critical:
        return const Color(0xFFEF4444); // red-500
    }
  }

  Future<void> _confirmDeleteEntry(_ServantGradeEntry entry) async {
    if (_isLocked) return;

    final l10n = AppLocalizations.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.servantGradesDeleteAssessmentTitle),
          content: Text(
            l10n.servantGradesDeleteAssessmentBody(entry.gradeType),
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.commonDelete),
            ),
          ],
        );
      },
    );

    if (result != true) return;
    try {
      final client = SupabaseClientManager.instance.client;
      await client.from('assessments').delete().eq('id', entry.id);
      await _loadGradeEntries();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.servantGradesDeleteAssessmentFailed)),
      );
    }
  }

  void _selectSubject(_ServantGradesSubject subject) {
    setState(() {
      _selectedSubject = subject;
      _view = _ServantGradesView.list;
      _selectedEntry = null;
      _showWeightedGrades = false;
      _weightedSearch = '';
      _viewingScoresEntryId = null;
    });
  }

  void _goToAdd() {
    if (_isLocked) return;
    _resetAssessmentForm();
    setState(() {
      _view = _ServantGradesView.add;
      _selectedEntry = null;
    });
  }

  void _goToEdit(_ServantGradeEntry entry) {
    if (_isLocked) return;
    _resetAssessmentForm(fromEntry: entry);
    setState(() {
      _selectedEntry = entry;
      _view = _ServantGradesView.edit;
    });
  }

  void _goToAddSubject() {
    if (_isLocked) return;
    _subjectNameController.text = '';
    setState(() {
      _view = _ServantGradesView.addSubject;
    });
  }

  void _goToMissing() {
    setState(() {
      _view = _ServantGradesView.missing;
      _showWeightedGrades = false;
    });
  }

  void _goToList() {
    setState(() {
      _view = _ServantGradesView.list;
      _selectedEntry = null;
      _studentScoresSearch = '';
      _studentScoresPage = 0;
    });
  }

  void _resetAssessmentForm({_ServantGradeEntry? fromEntry}) {
    _assessmentNameController.text = fromEntry?.gradeType ?? '';
    _maxScoreController.text = fromEntry == null
        ? ''
        : fromEntry.maxScore.toString();
    _weightController.text = fromEntry?.weight == null
        ? ''
        : fromEntry!.weight.toString();
    _assessmentDate = fromEntry?.date;
    _studentScoresSearch = '';
    _studentScoresPage = 0;

    for (final c in _studentScoreControllers.values) {
      c.dispose();
    }
    _studentScoreControllers.clear();

    for (final s in _students) {
      final value = fromEntry?.scores[s.id];
      _studentScoreControllers[s.id] = TextEditingController(
        text: value == null ? '' : value.toStringAsFixed(0),
      );
    }
  }

  Future<void> _pickAssessmentDate() async {
    if (_isLocked) return;
    final initial = _assessmentDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (picked == null) return;
    setState(() {
      _assessmentDate = picked;
    });
  }

  Future<void> _saveAssessment({required bool editing}) async {
    if (_isLocked) return;

    final l10n = AppLocalizations.of(context);

    final name = _assessmentNameController.text.trim();
    final maxScore = int.tryParse(_maxScoreController.text.trim());
    final weightText = _weightController.text.trim();
    final weight = weightText.isEmpty ? 0 : int.tryParse(weightText);
    final date = _assessmentDate;

    if (name.isEmpty || maxScore == null || maxScore <= 0 || date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.servantGradesFillRequiredFieldsError)),
      );
      return;
    }
    if (weight != null && (weight < 0 || weight > 100)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.servantGradesWeightRangeError)),
      );
      return;
    }

    final scores = <String, double?>{};
    for (final student in _students) {
      final raw = _studentScoreControllers[student.id]?.text.trim() ?? '';
      if (raw.isEmpty) {
        scores[student.id] = null;
        continue;
      }
      final v = double.tryParse(raw);
      if (v == null || v < 0 || v > maxScore) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.servantGradesInvalidScore(student.name, maxScore),
            ),
          ),
        );
        return;
      }
      scores[student.id] = v;
    }

    final subject = _selectedSubject;
    if (subject == null) return;

    try {
      final client = SupabaseClientManager.instance.client;
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Not signed in');

      final profile = await client
          .from('profiles')
          .select('grade_id')
          .eq('id', user.id)
          .maybeSingle();
      final gradeId = profile?['grade_id']?.toString() ?? _myGradeId;
      if (gradeId == null || gradeId.isEmpty) {
        throw Exception('Servant is not assigned to a grade');
      }

      final academicYear = await client
          .from('academic_years')
          .select('id')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final academicYearId =
          (academicYear?['id'] as String?) ?? _academicYearId;
      if (academicYearId == null || academicYearId.isEmpty) {
        throw Exception('No active academic year found');
      }

      final assessmentDate = date.toIso8601String().substring(0, 10);

      String assessmentId;
      if (editing) {
        final existingId = _selectedEntry?.id;
        if (existingId == null) return;
        await client
            .from('assessments')
            .update({
              'subject_id': subject.id,
              'grade_type': name,
              'max_score': maxScore,
              'weight': weight ?? 0,
              'assessment_date': assessmentDate,
            })
            .eq('id', existingId);
        assessmentId = existingId;
      } else {
        final inserted = await client
            .from('assessments')
            .insert({
              'academic_year_id': academicYearId,
              'grade_id': gradeId,
              'subject_id': subject.id,
              'grade_type': name,
              'max_score': maxScore,
              'weight': weight ?? 0,
              'assessment_date': assessmentDate,
              'created_by': user.id,
            })
            .select('id')
            .single();
        assessmentId = inserted['id'] as String;
      }

      final toUpsert = <Map<String, dynamic>>[];
      final toDeleteStudentIds = <String>[];
      scores.forEach((studentId, score) {
        if (score == null) {
          toDeleteStudentIds.add(studentId);
        } else {
          toUpsert.add({
            'assessment_id': assessmentId,
            'student_id': studentId,
            'score': score,
          });
        }
      });

      if (toDeleteStudentIds.isNotEmpty) {
        await client
            .from('assessment_scores')
            .delete()
            .eq('assessment_id', assessmentId)
            .inFilter('student_id', toDeleteStudentIds);
      }

      if (toUpsert.isNotEmpty) {
        await client
            .from('assessment_scores')
            .upsert(toUpsert, onConflict: 'assessment_id,student_id');
      }

      await _loadGradeEntries();
      if (!mounted) return;

      setState(() {
        _view = _ServantGradesView.list;
        _selectedEntry = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editing
                ? l10n.servantGradesAssessmentUpdated
                : l10n.servantGradesAssessmentAdded,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.servantGradesSaveAssessmentFailed)),
      );
    }
  }

  Future<void> _saveSubject() async {
    if (_isLocked) return;
    final l10n = AppLocalizations.of(context);
    final name = _subjectNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.servantGradesSubjectNameRequired)),
      );
      return;
    }
    try {
      final client = SupabaseClientManager.instance.client;
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Not signed in');

      final profile = await client
          .from('profiles')
          .select('grade_id')
          .eq('id', user.id)
          .maybeSingle();
      final gradeId = profile?['grade_id']?.toString() ?? _myGradeId;
      if (gradeId == null || gradeId.isEmpty) {
        throw Exception('Servant is not assigned to a grade');
      }

      await client.from('subjects').insert({
        'grade_id': gradeId,
        'name': name,
        'active': true,
      });

      await _loadSubjects();
      if (!mounted) return;
      setState(() {
        _view = _ServantGradesView.list;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.servantGradesSubjectAdded)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.servantGradesSubjectAddFailed)),
      );
    }
  }

  Widget _pill({
    required String text,
    Color bg = const Color(0xFFFEF3C7),
    Color fg = const Color(0xFFB45309),
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      prefixIcon: icon == null
          ? null
          : Icon(icon, size: 20, color: const Color(0xFF9CA3AF)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Color(0xFF0EA5E9), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final List<_ServantGradeEntry> entries = _selectedSubject != null
        ? _entriesForSelectedSubject()
        : <_ServantGradeEntry>[];
    final int totalWeight = _selectedSubject != null
        ? _totalWeightForSubject(_selectedSubject!.id)
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // slate-50
      body: SafeArea(
        child: (_loadingSubjects || _loadingStudents || _loadingGradeEntries)
            ? const Center(child: CircularProgressIndicator())
            : (_subjectsError ?? _studentsError ?? _gradeEntriesError) != null
            ? Center(
                child: Text(
                  (_subjectsError ?? _studentsError ?? _gradeEntriesError)!,
                ),
              )
            : _subjects.isEmpty
            ? Center(child: Text(l10n.commonNoSubjectsForGrade))
            : NestedScrollView(
                headerSliverBuilder: (context, _) {
                  return [
                    SliverAppBar(
                      pinned: true,
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.white,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      automaticallyImplyLeading: false,
                      toolbarHeight: 64,
                      titleSpacing: 24,
                      title: Text(
                        l10n.servantGradesManageTitle,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(92),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!_loadingLockState &&
                                _isLocked &&
                                _lockMessage != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  0,
                                  24,
                                  10,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7), // amber-100
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFFDE68A,
                                      ), // amber-200
                                    ),
                                  ),
                                  child: Text(
                                    _lockMessage!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF78350F),
                                    ),
                                  ),
                                ),
                              ),
                            SizedBox(
                              height: 46,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                children: [
                                  for (final s in _subjects) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: _SubjectChip(
                                        selected:
                                            _selectedSubject != null &&
                                            s.id == _selectedSubject!.id,
                                        label: s.name,
                                        onTap: () => _selectSubject(s),
                                      ),
                                    ),
                                  ],
                                  _SubjectChip(
                                    selected: false,
                                    label: l10n.servantGradesNewSubjectChip,
                                    tone: _ChipTone.amber,
                                    icon: Icons.add_rounded,
                                    onTap: _goToAddSubject,
                                    disabled: _isLocked,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              height: 1,
                              color: const Color(0xFFE2E8F0), // slate-200
                            ),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: switch (_view) {
                      _ServantGradesView.list => _buildList(
                        entries: entries,
                        totalWeight: totalWeight,
                      ),
                      _ServantGradesView.add => _buildAssessmentForm(
                        editing: false,
                      ),
                      _ServantGradesView.edit => _buildAssessmentForm(
                        editing: true,
                      ),
                      _ServantGradesView.addSubject => _buildAddSubjectForm(),
                      _ServantGradesView.missing => _buildMissingView(
                        entries: entries,
                      ),
                    },
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildList({
    required List<_ServantGradeEntry> entries,
    required int totalWeight,
  }) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('servant-grades-list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (entries.isNotEmpty) _buildWeightSummary(totalWeight),
        const SizedBox(height: 12),

        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _isLocked ? null : _goToAdd,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B), // amber-500
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.servantGradesAddNewAssessment),
          ),
        ),

        if (entries.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _showWeightedGrades = !_showWeightedGrades;
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9), // sky-500
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.trending_up_rounded),
                    label: Text(
                      _showWeightedGrades
                          ? l10n.servantGradesHideGrades
                          : l10n.servantGradesAllGrades,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _goToMissing,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444), // red-500
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.error_outline_rounded),
                    label: Text(l10n.servantGradesMissing),
                  ),
                ),
              ),
            ],
          ),
        ],

        if (_showWeightedGrades && entries.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildWeightedGradesCard(entries: entries, totalWeight: totalWeight),
        ],

        const SizedBox(height: 14),
        if (entries.isEmpty)
          _buildEmptyState()
        else
          ...entries.map(_buildEntryCard),
      ],
    );
  }

  Widget _buildWeightSummary(int totalWeight) {
    final l10n = AppLocalizations.of(context);
    final Color bg;
    final Color border;
    final Color fg;
    final String helper;
    if (totalWeight == 100) {
      bg = const Color(0xFFDCFCE7); // green-100
      border = const Color(0xFFBBF7D0); // green-200
      fg = const Color(0xFF16A34A); // green-600
      helper = '';
    } else if (totalWeight > 100) {
      bg = const Color(0xFFFEE2E2); // red-100
      border = const Color(0xFFFECACA); // red-200
      fg = const Color(0xFFDC2626); // red-600
      helper = l10n.servantGradesTotalWeightExceeds;
    } else {
      bg = const Color(0xFFFEF3C7); // amber-100
      border = const Color(0xFFFDE68A); // amber-200
      fg = const Color(0xFFB45309); // amber-700
      helper = l10n.servantGradesRemainingToReach100(100 - totalWeight);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.percent_rounded, color: fg, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.servantGradesTotalWeightLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              Text(
                '$totalWeight%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
          if (helper.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l10n.commonWarningMessage(helper),
              style: TextStyle(fontSize: 12, color: fg),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeightedGradesCard({
    required List<_ServantGradeEntry> entries,
    required int totalWeight,
  }) {
    final l10n = AppLocalizations.of(context);
    final subjectName = _selectedSubject?.name ?? '';

    final validScores = _selectedSubject == null
        ? <int>[]
        : _students
              .map((s) => _calculateSubjectAverage(s.id, _selectedSubject!.id))
              .whereType<int>()
              .toList();

    final classAvg = validScores.isEmpty
        ? null
        : (validScores.reduce((a, b) => a + b) / validScores.length).round();
    final highest = validScores.isEmpty
        ? null
        : validScores.reduce((a, b) => a > b ? a : b);
    final lowest = validScores.isEmpty
        ? null
        : validScores.reduce((a, b) => a < b ? a : b);

    final filteredStudents = _students
        .where(
          (s) => s.name.toLowerCase().contains(_weightedSearch.toLowerCase()),
        )
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14374151),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2FE), // sky-100
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      color: Color(0xFF0284C7),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.servantGradesWeightedTitle(subjectName),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.servantGradesWeightedBasedOn(
                    entries.length,
                    totalWeight,
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (v) => setState(() => _weightedSearch = v),
                  decoration: _inputDecoration(
                    hint: l10n.servantGradesWeightedSearchByStudentNameHint,
                    icon: Icons.search_rounded,
                  ),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final viewportWidth = constraints.maxWidth;
              final tableWidth = viewportWidth < 640 ? 640.0 : viewportWidth;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: tableWidth,
                    maxWidth: tableWidth,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        color: const Color(0xFFF8FAFC),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                l10n.servantGradesWeightedStudentNameHeader,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  l10n.servantGradesWeightedScoreHeader,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: EdgeInsets.only(left: 14),
                                child: Text(
                                  l10n.servantGradesWeightedGradeHeader,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final student in filteredStudents)
                        _buildWeightedRow(student: student, entries: entries),
                    ],
                  ),
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _stat(
                    label: l10n.servantGradesWeightedClassAverageLabel,
                    value: classAvg == null ? l10n.commonNa : '$classAvg%',
                    valueColor: const Color(0xFF0F172A),
                  ),
                ),
                Expanded(
                  child: _stat(
                    label: l10n.servantGradesWeightedHighestLabel,
                    value: highest == null ? l10n.commonNa : '$highest%',
                    valueColor: const Color(0xFF16A34A),
                  ),
                ),
                Expanded(
                  child: _stat(
                    label: l10n.servantGradesWeightedLowestLabel,
                    value: lowest == null ? l10n.commonNa : '$lowest%',
                    valueColor: const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildWeightedRow({
    required _ServantGradesStudent student,
    required List<_ServantGradeEntry> entries,
  }) {
    final l10n = AppLocalizations.of(context);
    final avg = _selectedSubject == null
        ? null
        : _calculateSubjectAverage(student.id, _selectedSubject!.id);
    final missing = entries.where((e) => e.scores[student.id] == null).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (avg == null && missing.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.servantGradesMissingLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final m in missing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF87171),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              m.gradeType,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                          if (m.weight != null)
                            Text(
                              '(${m.weight}%)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFB45309),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: avg == null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          l10n.servantGradesIncomplete,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.servantGradesMissingCount(missing.length),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      '$avg%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _gradeTextColor(avg),
                      ),
                    ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: avg == null
                  ? Center(
                      child: Text(
                        l10n.commonNa,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    )
                  : Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (avg.clamp(0, 100)) / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _gradeBarColor(avg),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(_ServantGradeEntry entry) {
    final l10n = AppLocalizations.of(context);
    final avg = _classAverageForEntry(entry);
    final dateLabel = EthiopianDateFormatter.formatDateTime(entry.date);
    final isOpen = _viewingScoresEntryId == entry.id;
    final search = _entryScoreSearch[entry.id] ?? '';
    final filtered = _students
        .where((s) => s.name.toLowerCase().contains(search.toLowerCase()))
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14374151),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.gradeType,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            if (entry.weight != null)
                              _pill(
                                text: '${entry.weight}%',
                                icon: Icons.percent_rounded,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  dateLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.description_outlined,
                                  size: 14,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.servantGradesMaxPoints(entry.maxScore),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: _isLocked ? null : () => _goToEdit(entry),
                    icon: const Icon(Icons.edit_outlined),
                    color: const Color(0xFF0EA5E9),
                    tooltip: l10n.servantGradesEditGradesTooltip,
                  ),
                  IconButton(
                    onPressed: _isLocked
                        ? null
                        : () => _confirmDeleteEntry(entry),
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: const Color(0xFFEF4444),
                    tooltip: l10n.servantGradesDeleteAssessmentTooltip,
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    l10n.servantGradesClassAverageLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$avg%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _gradeTextColor(avg),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (avg.clamp(0, 100)) / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _gradeBarColor(avg),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _viewingScoresEntryId = isOpen ? null : entry.id;
                  });
                },
                icon: Icon(
                  isOpen
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: const Color(0xFF0EA5E9),
                ),
                label: Text(
                  isOpen
                      ? l10n.servantGradesHideStudentScores
                      : l10n.servantGradesViewStudentScores,
                  style: const TextStyle(color: Color(0xFF0EA5E9)),
                ),
              ),

              if (isOpen) ...[
                TextField(
                  onChanged: (v) => setState(() {
                    _entryScoreSearch[entry.id] = v;
                  }),
                  decoration: _inputDecoration(
                    hint: l10n.servantGradesSearchStudentsHint,
                    icon: Icons.search_rounded,
                  ),
                ),
                const SizedBox(height: 10),
                for (final student in filtered)
                  _scoreRow(
                    name: student.name,
                    score: entry.scores[student.id],
                    maxScore: entry.maxScore,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreRow({
    required String name,
    required double? score,
    required int maxScore,
  }) {
    final l10n = AppLocalizations.of(context);
    final missing = score == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            if (missing)
              Text(
                l10n.servantGradesMissing,
                style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
              )
            else
              Text(
                '${score.toStringAsFixed(0)} / $maxScore',
                style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14374151),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.servantGradesNoAssessmentsYetTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            l10n.servantGradesNoAssessmentsYetBody,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentForm({required bool editing}) {
    final l10n = AppLocalizations.of(context);
    final title = editing
        ? l10n.servantGradesEditAssessmentTitle
        : l10n.servantGradesAddAssessmentTitle;
    final entry = editing ? _selectedEntry : null;
    final classAvg = entry == null ? null : _classAverageForEntry(entry);

    final filteredStudents = _students
        .where(
          (s) =>
              s.name.toLowerCase().contains(_studentScoresSearch.toLowerCase()),
        )
        .toList();
    final totalPages = (filteredStudents.length / _scoresPageSize).ceil();
    final currentPage = _studentScoresPage.clamp(
      0,
      (totalPages - 1).clamp(0, 999),
    );
    final start = currentPage * _scoresPageSize;
    final end = (start + _scoresPageSize).clamp(0, filteredStudents.length);
    final pageStudents = filteredStudents.sublist(start, end);

    return Column(
      key: ValueKey(editing ? 'servant-grades-edit' : 'servant-grades-add'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _goToList,
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: l10n.commonBack,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            if (editing && classAvg != null)
              _pill(
                text: l10n.servantGradesClassAvgLabel(classAvg),
                bg: const Color(0xFFE0F2FE),
                fg: const Color(0xFF0369A1),
                icon: Icons.trending_up_rounded,
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14374151),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _assessmentNameController,
                enabled: !_isLocked,
                decoration: _inputDecoration(
                  hint: l10n.servantGradesAssessmentNameHint,
                  icon: Icons.description_outlined,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _maxScoreController,
                      enabled: !_isLocked,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        hint: l10n.servantGradesMaxScoreHint,
                        icon: Icons.numbers_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      enabled: !_isLocked,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        hint: l10n.servantGradesWeightPercentOptionalHint,
                        icon: Icons.percent_rounded,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _isLocked ? null : _pickAssessmentDate,
                borderRadius: BorderRadius.circular(14),
                child: IgnorePointer(
                  child: TextField(
                    enabled: !_isLocked,
                    decoration: _inputDecoration(
                      hint: _assessmentDate == null
                          ? l10n.commonDate
                          : EthiopianDateFormatter.formatDateTime(
                              _assessmentDate!,
                            ),
                      icon: Icons.calendar_today_rounded,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.servantGradesStudentScoresOptional,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                enabled: !_isLocked,
                onChanged: (v) {
                  setState(() {
                    _studentScoresSearch = v;
                    _studentScoresPage = 0;
                  });
                },
                decoration: _inputDecoration(
                  hint: l10n.servantGradesSearchStudentsHint,
                  icon: Icons.search_rounded,
                ),
              ),
              const SizedBox(height: 10),
              if (totalPages > 1)
                Row(
                  children: [
                    Text(
                      l10n.servantGradesPageLabel(currentPage + 1, totalPages),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: !_isLocked && currentPage > 0
                          ? () => setState(
                              () => _studentScoresPage = currentPage - 1,
                            )
                          : null,
                      child: Text(l10n.commonPrev),
                    ),
                    TextButton(
                      onPressed: !_isLocked && currentPage < totalPages - 1
                          ? () => setState(
                              () => _studentScoresPage = currentPage + 1,
                            )
                          : null,
                      child: Text(l10n.commonNext),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              for (final s in pageStudents)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 110,
                          child: TextField(
                            enabled: !_isLocked,
                            controller: _studentScoreControllers[s.id],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.end,
                            decoration: _inputDecoration(
                              hint: l10n.servantGradesScoreHint,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _goToList,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        foregroundColor: const Color(0xFF334155),
                      ),
                      child: Text(l10n.commonCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isLocked
                          ? null
                          : () => _saveAssessment(editing: editing),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.save_rounded),
                      label: Text(l10n.commonSave),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddSubjectForm() {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('servant-grades-add-subject'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _goToList,
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: l10n.commonBack,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.servantGradesAddSubjectTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14374151),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                enabled: !_isLocked,
                controller: _subjectNameController,
                decoration: _inputDecoration(
                  hint: l10n.servantGradesSubjectNameHint,
                  icon: Icons.book_outlined,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _goToList,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        foregroundColor: const Color(0xFF334155),
                      ),
                      child: Text(l10n.commonCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isLocked ? null : _saveSubject,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.save_rounded),
                      label: Text(l10n.commonSave),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMissingView({required List<_ServantGradeEntry> entries}) {
    final l10n = AppLocalizations.of(context);
    final studentsWithMissing =
        <_ServantGradesStudent, List<_ServantGradeEntry>>{};
    for (final student in _students) {
      final missing = entries
          .where((e) => e.scores[student.id] == null)
          .toList();
      if (missing.isNotEmpty) {
        studentsWithMissing[student] = missing;
      }
    }

    return Column(
      key: const ValueKey('servant-grades-missing'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _goToList,
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: l10n.commonBack,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.servantGradesMissingAssessmentsTitle(
                _selectedSubject?.name ?? '',
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Text(
            l10n.servantGradesStudentsWithIncompleteAssessments(
              studentsWithMissing.length,
            ),
            style: const TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
          ),
        ),
        const SizedBox(height: 12),
        if (studentsWithMissing.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14374151),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              l10n.servantGradesNoMissingAssessmentsFound,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          )
        else
          for (final e in studentsWithMissing.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14374151),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.key.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final missing in e.value)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 16,
                              color: Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                missing.gradeType,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                            if (missing.weight != null)
                              Text(
                                '${missing.weight}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

enum _ChipTone { sky, amber }

class _SubjectChip extends StatelessWidget {
  const _SubjectChip({
    required this.selected,
    required this.label,
    required this.onTap,
    this.tone = _ChipTone.sky,
    this.icon,
    this.disabled = false,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final _ChipTone tone;
  final IconData? icon;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final isSky = tone == _ChipTone.sky;
    final selectedBg = isSky
        ? const Color(0xFF0EA5E9)
        : const Color(0xFFFDE68A);
    final selectedFg = isSky ? Colors.white : const Color(0xFF92400E);

    final bg = selected
        ? selectedBg
        : (isSky ? const Color(0xFFF1F5F9) : const Color(0xFFFEF3C7));
    final fg = selected
        ? selectedFg
        : (isSky ? const Color(0xFF334155) : const Color(0xFFB45309));

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: disabled ? 0.6 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServantCommunicationScreen extends StatelessWidget {
  const ServantCommunicationScreen({super.key, this.initialTab});

  final String? initialTab;

  @override
  Widget build(BuildContext context) {
    return _ServantCommunicationBody(initialTab: initialTab);
  }
}

class _ServantCommunicationBody extends StatefulWidget {
  const _ServantCommunicationBody({this.initialTab});

  final String? initialTab;

  @override
  State<_ServantCommunicationBody> createState() =>
      _ServantCommunicationBodyState();
}

enum _ServantCommTab { announcements, questions, complaints, feedback }

class _ServantCommunicationBodyState extends State<_ServantCommunicationBody> {
  _ServantCommTab _activeTab = _ServantCommTab.announcements;

  @override
  void didUpdateWidget(covariant _ServantCommunicationBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab == widget.initialTab) return;
    final parsed = _parseTab(widget.initialTab);
    if (parsed == null) return;
    setState(() {
      _activeTab = parsed;
      _showAnnouncementForm = false;
      _showCreateFeedback = false;
      _viewingFeedbackFormId = null;
    });
  }

  static _ServantCommTab? _parseTab(String? value) {
    final v = (value ?? '').trim().toLowerCase();
    switch (v) {
      case 'announcements':
        return _ServantCommTab.announcements;
      case 'questions':
        return _ServantCommTab.questions;
      case 'complaints':
        return _ServantCommTab.complaints;
      case 'feedback':
        return _ServantCommTab.feedback;
    }
    return null;
  }

  bool _showAnnouncementForm = false;

  bool _showCreateFeedback = false;
  String? _viewingFeedbackFormId;
  bool _showFeedbackSuccessToast = false;

  String? _activeAcademicYearId;
  String? _myGradeId;
  final Map<String, int> _feedbackSubmissionCounts = {};

  final _announcementTitleController = TextEditingController();
  final _announcementMessageController = TextEditingController();
  String _announcementCategory = 'general';
  final String _announcementTargetAudience = 'students';
  final String _announcementPriority = 'medium';
  // ignore: unused_field
  String? _announcementExpiresOn;

  bool _loadingAnnouncements = true;
  String? _announcementsError;

  final List<_ServantAnnouncement> _announcements = [];
  String? _expandedAnnouncementId;

  bool _loadingQuestions = true;
  String? _questionsError;

  final List<_ServantQuestion> _questions = [];

  String _questionStatusFilter = 'all'; // all | pending | answered
  String _questionSubjectFilter = 'all';
  String? _respondingQuestionId;
  final Map<String, TextEditingController> _questionReplyControllers = {};

  bool _loadingComplaints = true;
  String? _complaintsError;

  final List<_ServantComplaint> _complaints = [];

  String _complaintStatusFilter = 'all'; // all | pending | in-review | resolved
  String _complaintCategoryFilter = 'all';
  String? _respondingComplaintId;
  final Map<String, TextEditingController> _complaintReplyControllers = {};
  final Map<String, String> _complaintNextStatus = {};

  int? _totalStudentsInGrade;

  bool _loadingFeedback = true;
  String? _feedbackError;

  final _feedbackTitleController = TextEditingController();
  final _feedbackDescriptionController = TextEditingController();
  String _feedbackType = '';
  String _feedbackStartDate = '';
  String _feedbackEndDate = '';

  final List<_DraftFeedbackQuestion> _draftFeedbackQuestions = [];
  bool _showAddFeedbackQuestion = false;
  final _draftQuestionTextController = TextEditingController();
  String _draftQuestionType = 'rating';
  bool _draftQuestionRequired = true;
  final List<TextEditingController> _draftOptionControllers = [
    TextEditingController(),
  ];

  final List<_ServantFeedbackForm> _feedbackForms = [];

  bool _loadingFeedbackResponses = false;
  String? _feedbackResponsesError;

  final List<_ServantFeedbackResponse> _feedbackResponses = [];

  @override
  void initState() {
    super.initState();
    final parsed = _parseTab(widget.initialTab);
    if (parsed != null) {
      _activeTab = parsed;
    }
    _loadFeedbackFromBackend();
    _loadAnnouncementsFromBackend();
    _loadQuestionsFromBackend();
    _loadComplaintsFromBackend();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppRefreshScope.of(context).setOnRefresh(_handlePullToRefresh);
    });
  }

  Future<void> _handlePullToRefresh() async {
    await Future.wait([
      _loadFeedbackFromBackend(),
      _loadAnnouncementsFromBackend(),
      _loadQuestionsFromBackend(),
      _loadComplaintsFromBackend(),
    ]);
  }

  @override
  void dispose() {
    try {
      AppRefreshScope.of(context).setOnRefresh(null);
    } catch (_) {}
    _announcementTitleController.dispose();
    _announcementMessageController.dispose();
    _feedbackTitleController.dispose();
    _feedbackDescriptionController.dispose();
    _draftQuestionTextController.dispose();
    for (final c in _draftOptionControllers) {
      c.dispose();
    }
    for (final c in _questionReplyControllers.values) {
      c.dispose();
    }
    for (final c in _complaintReplyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<({String? userId, String? academicYearId, String? gradeId})>
  _ensureContextLoaded() async {
    final client = SupabaseClientManager.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      return (userId: null, academicYearId: null, gradeId: null);
    }

    if (_activeAcademicYearId != null &&
        _myGradeId != null &&
        _totalStudentsInGrade != null) {
      return (
        userId: userId,
        academicYearId: _activeAcademicYearId,
        gradeId: _myGradeId,
      );
    }

    String? activeAcademicYearId = _activeAcademicYearId;
    String? myGradeId = _myGradeId;
    int? totalStudentsInGrade = _totalStudentsInGrade;

    try {
      final academicYear = await client
          .from('academic_years')
          .select('id')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      activeAcademicYearId ??= academicYear?['id'] as String?;
    } catch (_) {}

    try {
      final profile = await client
          .from('profiles')
          .select('grade_id')
          .eq('id', userId)
          .maybeSingle();
      myGradeId ??= profile?['grade_id'] as String?;
    } catch (_) {}

    if (totalStudentsInGrade == null && myGradeId != null) {
      try {
        final rows = await client
            .from('profiles')
            .select('id')
            .eq('role', 'student')
            .eq('grade_id', myGradeId);
        totalStudentsInGrade = (rows as List).length;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _activeAcademicYearId = activeAcademicYearId;
        _myGradeId = myGradeId;
        _totalStudentsInGrade = totalStudentsInGrade;
      });
    } else {
      _activeAcademicYearId = activeAcademicYearId;
      _myGradeId = myGradeId;
      _totalStudentsInGrade = totalStudentsInGrade;
    }

    return (
      userId: userId,
      academicYearId: activeAcademicYearId,
      gradeId: myGradeId,
    );
  }

  static String _dateOnly(String value) {
    if (value.length >= 10) return value.substring(0, 10);
    return value;
  }

  static String _complaintStatusFromDb(String status) {
    if (status == 'in_review') return 'in-review';
    return status;
  }

  static String _complaintStatusToDb(String status) {
    if (status == 'in-review') return 'in_review';
    return status;
  }

  Future<void> _loadAnnouncementsFromBackend() async {
    final client = SupabaseClientManager.instance.client;

    if (mounted) {
      setState(() {
        _loadingAnnouncements = true;
        _announcementsError = null;
      });
    } else {
      _loadingAnnouncements = true;
      _announcementsError = null;
    }

    final ctx = await _ensureContextLoaded();
    final userId = ctx.userId;
    final gradeId = ctx.gradeId;
    final academicYearId = ctx.academicYearId;
    if (userId == null || gradeId == null) {
      if (!mounted) return;
      setState(() {
        _announcements.clear();
        _expandedAnnouncementId = null;
        _loadingAnnouncements = false;
      });
      return;
    }

    try {
      var query = client
          .from('announcements')
          .select(
            'id, title, message, category, priority, created_by, created_at, expires_on, active, grade_id, academic_year_id',
          )
          .eq('active', true);

      if (academicYearId != null) {
        query = query.eq('academic_year_id', academicYearId);
      }

      query = query.or('grade_id.is.null,grade_id.eq.$gradeId');

      final rows = await query.order('created_at', ascending: false);
      final items = rows.map((r) {
        final map = r as Map;
        final createdAt = map['created_at']?.toString() ?? '';
        final createdById = map['created_by']?.toString() ?? '';
        return _ServantAnnouncement(
          id: map['id'] as String,
          title: (map['title'] as String?) ?? '',
          message: (map['message'] as String?) ?? '',
          category: (map['category'] as String?) ?? 'general',
          createdBy: createdById == userId ? 'You' : 'Servant',
          createdDate: createdAt.isNotEmpty
              ? _dateOnly(createdAt)
              : _todayIso(),
          priority: (map['priority'] as String?) ?? 'medium',
          targetAudience: 'students',
          expiresOn: (map['expires_on'] as String?),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _announcements
          ..clear()
          ..addAll(items);
        _expandedAnnouncementId = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _announcements.clear();
        _expandedAnnouncementId = null;
        _announcementsError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingAnnouncements = false;
      });
    }
  }

  Future<_ServantAnnouncement?> _createAnnouncementInBackend({
    required String title,
    required String message,
    required String category,
    required String priority,
    required String targetAudience,
    String? expiresOnIso,
  }) async {
    final client = SupabaseClientManager.instance.client;
    final ctx = await _ensureContextLoaded();
    final userId = ctx.userId;
    final gradeId = ctx.gradeId;
    final academicYearId = ctx.academicYearId;
    if (userId == null || gradeId == null) return null;

    final expires = (expiresOnIso ?? '').trim();
    final validExpires = DateTime.tryParse(expires) != null ? expires : null;

    final inserted = await client
        .from('announcements')
        .insert({
          'academic_year_id': academicYearId,
          'grade_id': gradeId,
          'title': title,
          'message': message,
          'category': category,
          'priority': priority,
          'created_by': userId,
          'expires_on': validExpires,
          'active': true,
        })
        .select(
          'id, title, message, category, priority, created_by, created_at, expires_on',
        )
        .single();

    try {
      await client.functions.invoke(
        'push-notify',
        body: {
          'event': 'announcement_created',
          'announcementId': inserted['id'],
        },
      );
    } catch (_) {}

    final createdAt = inserted['created_at']?.toString() ?? '';
    return _ServantAnnouncement(
      id: inserted['id'] as String,
      title: inserted['title'] as String,
      message: inserted['message'] as String,
      category: (inserted['category'] as String?) ?? 'general',
      createdBy: 'You',
      createdDate: createdAt.isNotEmpty ? _dateOnly(createdAt) : _todayIso(),
      priority: (inserted['priority'] as String?) ?? 'medium',
      targetAudience: targetAudience,
      expiresOn: inserted['expires_on'] as String?,
    );
  }

  Future<bool> _deleteAnnouncementInBackend(String id) async {
    final client = SupabaseClientManager.instance.client;
    try {
      await client.from('announcements').delete().eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadQuestionsFromBackend() async {
    final client = SupabaseClientManager.instance.client;

    if (mounted) {
      setState(() {
        _loadingQuestions = true;
        _questionsError = null;
      });
    } else {
      _loadingQuestions = true;
      _questionsError = null;
    }

    final ctx = await _ensureContextLoaded();
    final userId = ctx.userId;
    final gradeId = ctx.gradeId;
    final academicYearId = ctx.academicYearId;
    if (userId == null || gradeId == null || academicYearId == null) {
      if (!mounted) return;
      setState(() {
        _questions.clear();
        _respondingQuestionId = null;
        _loadingQuestions = false;
      });
      return;
    }

    try {
      final rows = await client
          .from('questions')
          .select(
            'id, student_id, subject_id, question, created_at, answered, answer, answered_by, answered_at',
          )
          .eq('grade_id', gradeId)
          .eq('academic_year_id', academicYearId)
          .order('created_at', ascending: false);

      final studentIds = <String>{};
      final subjectIds = <String>{};
      for (final r in rows) {
        final map = r as Map;
        final sid = map['student_id']?.toString();
        final subId = map['subject_id']?.toString();
        if (sid != null && sid.isNotEmpty) studentIds.add(sid);
        if (subId != null && subId.isNotEmpty) subjectIds.add(subId);
      }

      final studentNames = <String, String>{};
      if (studentIds.isNotEmpty) {
        try {
          final profiles = await client
              .from('profiles')
              .select('id, name')
              .inFilter('id', studentIds.toList());
          for (final p in profiles) {
            final m = p as Map;
            final id = m['id']?.toString();
            if (id == null) continue;
            studentNames[id] = (m['name'] as String?) ?? 'Student';
          }
        } catch (_) {}
      }

      final subjectNames = <String, String>{};
      if (subjectIds.isNotEmpty) {
        try {
          final subjects = await client
              .from('subjects')
              .select('id, name')
              .inFilter('id', subjectIds.toList());
          for (final s in subjects) {
            final m = s as Map;
            final id = m['id']?.toString();
            if (id == null) continue;
            subjectNames[id] = (m['name'] as String?) ?? 'General';
          }
        } catch (_) {}
      }

      final items = rows.map((r) {
        final map = r as Map;
        final createdAt = map['created_at']?.toString() ?? '';
        final answeredAt = map['answered_at']?.toString();
        final studentId = map['student_id']?.toString() ?? '';
        final subjectId = map['subject_id']?.toString();
        final answeredById = map['answered_by']?.toString();

        return _ServantQuestion(
          id: map['id'] as String,
          studentId: studentId,
          studentName: studentNames[studentId] ?? 'Student',
          subjectId: subjectId ?? '',
          subjectName: (subjectId == null || subjectId.isEmpty)
              ? 'General'
              : (subjectNames[subjectId] ?? 'General'),
          question: (map['question'] as String?) ?? '',
          date: createdAt.isNotEmpty ? _dateOnly(createdAt) : _todayIso(),
          answered: (map['answered'] as bool?) ?? false,
          answer: map['answer'] as String?,
          answeredBy: answeredById == null
              ? null
              : (answeredById == userId ? 'You' : 'Servant'),
          answeredDate: answeredAt == null ? null : _dateOnly(answeredAt),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _questions
          ..clear()
          ..addAll(items);
        _respondingQuestionId = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _questions.clear();
        _respondingQuestionId = null;
        _questionsError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingQuestions = false;
      });
    }
  }

  Future<bool> _answerQuestionInBackend({
    required String questionId,
    required String reply,
  }) async {
    final client = SupabaseClientManager.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await client
          .from('questions')
          .update({
            'answered': true,
            'answer': reply,
            'answered_by': userId,
            'answered_at': DateTime.now().toIso8601String(),
          })
          .eq('id', questionId);

      try {
        await client.functions.invoke(
          'push-notify',
          body: {'event': 'question_answered', 'questionId': questionId},
        );
      } catch (_) {}
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _deleteQuestionInBackend(String id) async {
    final client = SupabaseClientManager.instance.client;
    try {
      await client.from('questions').delete().eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadComplaintsFromBackend() async {
    final client = SupabaseClientManager.instance.client;

    if (mounted) {
      setState(() {
        _loadingComplaints = true;
        _complaintsError = null;
      });
    } else {
      _loadingComplaints = true;
      _complaintsError = null;
    }

    final ctx = await _ensureContextLoaded();
    final userId = ctx.userId;
    final gradeId = ctx.gradeId;
    final academicYearId = ctx.academicYearId;
    if (userId == null || gradeId == null || academicYearId == null) {
      if (!mounted) return;
      setState(() {
        _complaints.clear();
        _respondingComplaintId = null;
        _complaintNextStatus.clear();
        _loadingComplaints = false;
      });
      return;
    }

    try {
      final rows = await client
          .from('complaints')
          .select(
            'id, student_id, category, complaint, created_at, status, response, responded_by, responded_at',
          )
          .eq('grade_id', gradeId)
          .eq('academic_year_id', academicYearId)
          .order('created_at', ascending: false);

      final studentIds = <String>{};
      for (final r in rows) {
        final map = r as Map;
        final sid = map['student_id']?.toString();
        if (sid != null && sid.isNotEmpty) studentIds.add(sid);
      }

      final studentNames = <String, String>{};
      if (studentIds.isNotEmpty) {
        try {
          final profiles = await client
              .from('profiles')
              .select('id, name')
              .inFilter('id', studentIds.toList());
          for (final p in profiles) {
            final m = p as Map;
            final id = m['id']?.toString();
            if (id == null) continue;
            studentNames[id] = (m['name'] as String?) ?? 'Student';
          }
        } catch (_) {}
      }

      final items = rows.map((r) {
        final map = r as Map;
        final createdAt = map['created_at']?.toString() ?? '';
        final respondedAt = map['responded_at']?.toString();
        final studentId = map['student_id']?.toString() ?? '';
        final respondedById = map['responded_by']?.toString();
        final statusDb = (map['status'] as String?) ?? 'pending';

        return _ServantComplaint(
          id: map['id'] as String,
          studentId: studentId,
          studentName: studentNames[studentId] ?? 'Student',
          category: (map['category'] as String?) ?? 'other',
          complaint: (map['complaint'] as String?) ?? '',
          date: createdAt.isNotEmpty ? _dateOnly(createdAt) : _todayIso(),
          status: _complaintStatusFromDb(statusDb),
          response: map['response'] as String?,
          respondedBy: respondedById == null
              ? null
              : (respondedById == userId ? 'You' : 'Servant'),
          respondedDate: respondedAt == null ? null : _dateOnly(respondedAt),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _complaints
          ..clear()
          ..addAll(items);
        _respondingComplaintId = null;
        _complaintNextStatus.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _complaints.clear();
        _respondingComplaintId = null;
        _complaintNextStatus.clear();
        _complaintsError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingComplaints = false;
      });
    }
  }

  Future<bool> _updateComplaintInBackend({
    required String complaintId,
    required String reply,
    required String newStatusUi,
  }) async {
    final client = SupabaseClientManager.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await client
          .from('complaints')
          .update({
            'response': reply,
            'status': _complaintStatusToDb(newStatusUi),
            'responded_by': userId,
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', complaintId);

      try {
        await client.functions.invoke(
          'push-notify',
          body: {'event': 'complaint_responded', 'complaintId': complaintId},
        );
      } catch (_) {}
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _deleteComplaintInBackend(String id) async {
    final client = SupabaseClientManager.instance.client;
    try {
      await client.from('complaints').delete().eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _deleteFeedbackFormInBackend(String id) async {
    final client = SupabaseClientManager.instance.client;
    try {
      await client.from('feedback_forms').delete().eq('id', id);
      return true;
    } catch (_) {
      try {
        await client.from('feedback_submissions').delete().eq('form_id', id);
      } catch (_) {}
      try {
        await client.from('feedback_questions').delete().eq('form_id', id);
      } catch (_) {}
      try {
        await client.from('feedback_forms').delete().eq('id', id);
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Future<void> _loadFeedbackFromBackend() async {
    final client = SupabaseClientManager.instance.client;

    if (mounted) {
      setState(() {
        _loadingFeedback = true;
        _feedbackError = null;
      });
    } else {
      _loadingFeedback = true;
      _feedbackError = null;
    }

    final ctx = await _ensureContextLoaded();
    final userId = ctx.userId;
    final gradeId = ctx.gradeId;
    final academicYearId = ctx.academicYearId;
    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _feedbackForms.clear();
        _feedbackSubmissionCounts.clear();
        _loadingFeedback = false;
      });
      return;
    }

    try {
      var query = client
          .from('feedback_forms')
          .select(
            'id, title, description, type_label, start_date, end_date, created_at, created_by, academic_year_id, grade_id, feedback_questions(id, position, type, question, required, options)',
          );

      if (academicYearId != null) {
        query = query.eq('academic_year_id', academicYearId);
      }
      if (gradeId != null) {
        query = query.eq('grade_id', gradeId);
      }

      final formsRaw = await query.order('created_at', ascending: false);
      final forms = <_ServantFeedbackForm>[];
      final counts = <String, int>{};

      for (final row in formsRaw) {
        final formId = row['id'] as String;
        final questionsRaw =
            (row['feedback_questions'] as List<dynamic>? ?? const []);

        questionsRaw.sort((a, b) {
          final pa = (a as Map)['position'] as int? ?? 0;
          final pb = (b as Map)['position'] as int? ?? 0;
          return pa.compareTo(pb);
        });

        final questions = questionsRaw.map((q) {
          final map = q as Map;
          final optionsRaw = map['options'];
          final options = optionsRaw is List
              ? optionsRaw.whereType<String>().toList()
              : const <String>[];

          return _ServantFeedbackQuestion(
            id: map['id'] as String,
            question: (map['question'] as String?) ?? '',
            type: (map['type'] as String?) ?? 'text',
            required: (map['required'] as bool?) ?? true,
            options: options,
          );
        }).toList();

        final createdAt = row['created_at']?.toString() ?? '';
        final createdDate = createdAt.isNotEmpty
            ? createdAt.substring(0, 10)
            : _todayIso();

        final createdById = row['created_by']?.toString() ?? '';
        final createdBy = createdById == userId ? 'You' : 'Admin';

        forms.add(
          _ServantFeedbackForm(
            id: formId,
            title: (row['title'] as String?) ?? '',
            description: (row['description'] as String?) ?? '',
            type: (row['type_label'] as String?) ?? 'general',
            createdBy: createdBy,
            createdDate: createdDate,
            startDate: (row['start_date'] as String?) ?? _todayIso(),
            endDate: (row['end_date'] as String?) ?? _todayIso(),
            status: 'active',
            targetStudents: const ['all'],
            questions: questions,
          ),
        );

        try {
          final submissions = await client
              .from('feedback_submissions')
              .select('id')
              .eq('form_id', formId);
          counts[formId] = submissions.length;
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _feedbackForms
          ..clear()
          ..addAll(forms);
        _feedbackSubmissionCounts
          ..clear()
          ..addAll(counts);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feedbackForms.clear();
        _feedbackSubmissionCounts.clear();
        _feedbackError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingFeedback = false;
      });
    }
  }

  Future<void> _loadFeedbackResponsesForForm(String formId) async {
    final client = SupabaseClientManager.instance.client;

    if (mounted) {
      setState(() {
        _loadingFeedbackResponses = true;
        _feedbackResponsesError = null;
      });
    } else {
      _loadingFeedbackResponses = true;
      _feedbackResponsesError = null;
    }

    try {
      final rows = await client
          .from('feedback_submissions')
          .select('id, student_id, submitted_at, answers')
          .eq('form_id', formId)
          .order('submitted_at', ascending: false);

      final studentIds = <String>{};
      for (final r in rows) {
        final map = r as Map;
        final sid = map['student_id']?.toString();
        if (sid != null && sid.isNotEmpty) studentIds.add(sid);
      }

      final studentNames = <String, String>{};
      if (studentIds.isNotEmpty) {
        try {
          final profiles = await client
              .from('profiles')
              .select('id, name')
              .inFilter('id', studentIds.toList());
          for (final p in profiles) {
            final m = p as Map;
            final id = m['id']?.toString();
            if (id == null) continue;
            studentNames[id] = (m['name'] as String?) ?? 'Student';
          }
        } catch (_) {}
      }

      final responses = rows.map((r) {
        final map = r as Map;
        final answersDynamic = map['answers'];
        final answers = answersDynamic is Map<String, dynamic>
            ? answersDynamic
            : <String, Object?>{};

        final submittedAt = map['submitted_at']?.toString() ?? '';
        final submittedDate = submittedAt.isNotEmpty
            ? submittedAt.substring(0, 10)
            : _todayIso();

        final studentId = map['student_id']?.toString() ?? '';

        return _ServantFeedbackResponse(
          id: map['id'] as String,
          formId: formId,
          studentId: studentId,
          studentName: studentNames[studentId] ?? 'Student',
          submittedDate: submittedDate,
          answers: answers,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _feedbackResponses.removeWhere((r) => r.formId == formId);
        _feedbackResponses.addAll(responses);
        _feedbackSubmissionCounts[formId] = responses.length;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feedbackResponses.removeWhere((r) => r.formId == formId);
        _feedbackSubmissionCounts.remove(formId);
        _feedbackResponsesError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingFeedbackResponses = false;
      });
    }
  }

  Future<_ServantFeedbackForm?> _createFeedbackFormInBackend({
    required String title,
    required String description,
    required String typeLabel,
    required String startDateIso,
    required String endDateIso,
    required List<_ServantFeedbackQuestion> questions,
  }) async {
    final client = SupabaseClientManager.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    final academicYearId = _activeAcademicYearId;
    final gradeId = _myGradeId;
    if (academicYearId == null || gradeId == null) {
      return null;
    }

    final inserted = await client
        .from('feedback_forms')
        .insert({
          'academic_year_id': academicYearId,
          'grade_id': gradeId,
          'created_by': userId,
          'type_label': typeLabel,
          'title': title,
          'description': description,
          'start_date': startDateIso,
          'end_date': endDateIso,
        })
        .select(
          'id, title, description, type_label, start_date, end_date, created_at, created_by',
        )
        .single();

    final formId = inserted['id'] as String;

    if (questions.isNotEmpty) {
      await client
          .from('feedback_questions')
          .insert(
            questions.asMap().entries.map((e) {
              final q = e.value;
              return {
                'form_id': formId,
                'position': e.key + 1,
                'type': q.type,
                'question': q.question,
                'required': q.required,
                'options': q.options.isEmpty ? null : q.options,
              };
            }).toList(),
          );
    }

    try {
      await client.functions.invoke(
        'push-notify',
        body: {'event': 'feedback_form_created', 'formId': formId},
      );
    } catch (_) {}

    final createdAt = inserted['created_at']?.toString() ?? '';
    final createdDate = createdAt.isNotEmpty
        ? createdAt.substring(0, 10)
        : _todayIso();

    return _ServantFeedbackForm(
      id: formId,
      title: inserted['title'] as String,
      description: inserted['description'] as String,
      type: inserted['type_label'] as String,
      createdBy: 'You',
      createdDate: createdDate,
      startDate: inserted['start_date'] as String,
      endDate: inserted['end_date'] as String,
      status: 'active',
      targetStudents: const ['all'],
      questions: questions,
    );
  }

  int get _pendingQuestionsCount => _questions.where((q) => !q.answered).length;

  int get _pendingComplaintsCount =>
      _complaints.where((c) => c.status == 'pending').length;

  TextEditingController _questionControllerFor(String questionId) {
    return _questionReplyControllers.putIfAbsent(
      questionId,
      () => TextEditingController(),
    );
  }

  TextEditingController _complaintControllerFor(String complaintId) {
    return _complaintReplyControllers.putIfAbsent(
      complaintId,
      () => TextEditingController(),
    );
  }

  Future<bool> _confirmDelete({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _resetInlineEditors() {
    _respondingQuestionId = null;
    _respondingComplaintId = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 24,
                    bottom: 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).navCommunication,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppLocalizations.of(context).servantCommSubtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _ServantCommTabButton(
                              label: AppLocalizations.of(
                                context,
                              ).commAnnouncements,
                              icon: Icons.campaign_rounded,
                              selected:
                                  _activeTab == _ServantCommTab.announcements,
                              onTap: () {
                                setState(() {
                                  _activeTab = _ServantCommTab.announcements;
                                  _resetInlineEditors();
                                  _showAnnouncementForm = false;
                                  _showCreateFeedback = false;
                                  _viewingFeedbackFormId = null;
                                });
                              },
                            ),
                            _ServantCommTabButton(
                              label: AppLocalizations.of(context).commQuestions,
                              icon: Icons.question_answer_rounded,
                              selected: _activeTab == _ServantCommTab.questions,
                              badgeCount: _pendingQuestionsCount,
                              badgeStyle: _ServantBadgeStyle.amber,
                              onTap: () {
                                setState(() {
                                  _activeTab = _ServantCommTab.questions;
                                  _resetInlineEditors();
                                  _showAnnouncementForm = false;
                                  _showCreateFeedback = false;
                                  _viewingFeedbackFormId = null;
                                });
                              },
                            ),
                            _ServantCommTabButton(
                              label: AppLocalizations.of(
                                context,
                              ).commComplaints,
                              icon: Icons.report_problem_rounded,
                              selected:
                                  _activeTab == _ServantCommTab.complaints,
                              badgeCount: _pendingComplaintsCount,
                              badgeStyle: _ServantBadgeStyle.red,
                              onTap: () {
                                setState(() {
                                  _activeTab = _ServantCommTab.complaints;
                                  _resetInlineEditors();
                                  _showAnnouncementForm = false;
                                  _showCreateFeedback = false;
                                  _viewingFeedbackFormId = null;
                                });
                              },
                            ),
                            _ServantCommTabButton(
                              label: AppLocalizations.of(context).commFeedback,
                              icon: Icons.fact_check_rounded,
                              selected: _activeTab == _ServantCommTab.feedback,
                              onTap: () {
                                setState(() {
                                  _activeTab = _ServantCommTab.feedback;
                                  _resetInlineEditors();
                                  _showAnnouncementForm = false;
                                  _showCreateFeedback = false;
                                  _viewingFeedbackFormId = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Builder(
                      builder: (context) {
                        switch (_activeTab) {
                          case _ServantCommTab.announcements:
                            return _buildAnnouncements();
                          case _ServantCommTab.questions:
                            return _buildQuestions();
                          case _ServantCommTab.complaints:
                            return _buildComplaints();
                          case _ServantCommTab.feedback:
                            return _buildFeedback();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (_showFeedbackSuccessToast)
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22374151),
                          blurRadius: 14,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Feedback form created successfully!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14374151),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildAnnouncements() {
    final l10n = AppLocalizations.of(context);
    const maxTitleChars = 100;
    const maxMessageChars = 500;

    String categoryEmoji(String category) {
      switch (category) {
        case 'urgent':
          return '🚨';
        case 'grades':
          return '📊';
        case 'schedule':
          return '📅';
        case 'event':
          return '🎉';
        case 'general':
        default:
          return '📢';
      }
    }

    String categoryLabel(String category) {
      switch (category) {
        case 'urgent':
          return l10n.commAnnouncementCategoryUrgent;
        case 'grades':
          return l10n.commAnnouncementCategoryGrades;
        case 'schedule':
          return l10n.commAnnouncementCategorySchedule;
        case 'event':
          return l10n.commAnnouncementCategoryEvent;
        case 'general':
        default:
          return l10n.commAnnouncementCategoryGeneral;
      }
    }

    ({Color bg, Color fg}) categoryColors(String category) {
      switch (category) {
        case 'urgent':
          return (bg: const Color(0xFFFEE2E2), fg: const Color(0xFFB91C1C));
        case 'grades':
          return (bg: const Color(0xFFFEF3C7), fg: const Color(0xFF92400E));
        case 'schedule':
          return (bg: const Color(0xFFDBEAFE), fg: const Color(0xFF1D4ED8));
        case 'event':
          return (bg: const Color(0xFFD1FAE5), fg: const Color(0xFF047857));
        case 'general':
        default:
          return (bg: const Color(0xFFF1F5F9), fg: const Color(0xFF475569));
      }
    }

    Widget categoryChip(String category) {
      final colors = categoryColors(category);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.fg.withValues(alpha: 0.25)),
        ),
        child: Text(
          categoryLabel(category),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colors.fg,
          ),
        ),
      );
    }

    Future<void> postAnnouncement() async {
      final title = _announcementTitleController.text.trim();
      final message = _announcementMessageController.text.trim();
      if (title.isEmpty || message.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.servantAnnouncementsEnterTitleAndMessageError),
          ),
        );
        return;
      }

      _ServantAnnouncement? created;
      try {
        created = await _createAnnouncementInBackend(
          title: title,
          message: message,
          category: _announcementCategory,
          priority: _announcementPriority,
          targetAudience: _announcementTargetAudience,
          expiresOnIso: null,
        );
      } catch (_) {}

      if (!mounted) return;

      if (created == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post announcement.')),
        );
        return;
      }

      final createdAnnouncement = created!;

      setState(() {
        _announcements.insert(0, createdAnnouncement);
        _announcementTitleController.clear();
        _announcementMessageController.clear();
        _announcementExpiresOn = null;
        _showAnnouncementForm = false;
      });
    }

    void cancelAnnouncement() {
      setState(() {
        _announcementTitleController.clear();
        _announcementMessageController.clear();
        _announcementExpiresOn = null;
        _showAnnouncementForm = false;
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_showAnnouncementForm)
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showAnnouncementForm = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                elevation: 1,
                shadowColor: const Color(0x14374151),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                l10n.servantAnnouncementsCreateTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        if (_showAnnouncementForm) ...[
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.servantAnnouncementsCreateTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: cancelAnnouncement,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _ServantLabeledField(
                  label: l10n.servantAnnouncementsCategoryLabel,
                  child: DropdownButtonFormField<String>(
                    initialValue: _announcementCategory,
                    decoration: _inputDecoration(
                      l10n.servantAnnouncementsSelectCategoryHint,
                    ),
                    items:
                        const [
                          'general',
                          'grades',
                          'schedule',
                          'event',
                          'urgent',
                        ].map((c) {
                          return DropdownMenuItem<String>(
                            value: c,
                            child: Text(
                              '${categoryEmoji(c)} ${categoryLabel(c)}',
                            ),
                          );
                        }).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _announcementCategory = v);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.commTitleLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _announcementTitleController,
                  maxLength: maxTitleChars,
                  buildCounter:
                      (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                  decoration: _inputDecoration(
                    l10n.servantAnnouncementsTitleHint,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_announcementTitleController.text.characters.length}/$maxTitleChars',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.servantAnnouncementsMessageLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _announcementMessageController,
                  minLines: 5,
                  maxLines: 8,
                  maxLength: maxMessageChars,
                  buildCounter:
                      (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                  decoration: _inputDecoration(
                    l10n.servantAnnouncementsMessageHint,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_announcementMessageController.text.characters.length}/$maxMessageChars',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: postAnnouncement,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          l10n.servantAnnouncementsPostButton,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: cancelAnnouncement,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334155),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.commonCancel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (!_showAnnouncementForm) ...[
          const SizedBox(height: 14),
          if (_loadingAnnouncements)
            const Center(child: CircularProgressIndicator())
          else if (_announcementsError != null)
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.commAnnouncementsLoadFailed,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _announcementsError!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _loadAnnouncementsFromBackend,
                      child: Text(l10n.commonRetry),
                    ),
                  ),
                ],
              ),
            )
          else if (_announcements.isEmpty)
            _ServantEmptyState(
              icon: Icons.campaign_rounded,
              title: l10n.servantAnnouncementsEmptyTitle,
              subtitle: l10n.servantAnnouncementsEmptySubtitle,
            )
          else
            Column(
              children: _announcements.map((a) {
                final expanded = _expandedAnnouncementId == a.id;
                final dateLabel = EthiopianDateFormatter.formatFlexible(
                  a.createdDate,
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14374151),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            _expandedAnnouncementId = expanded ? null : a.id;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 34),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      categoryEmoji(a.category),
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            a.title,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              categoryChip(a.category),
                                              Text(
                                                dateLabel,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                              Text(
                                                l10n.servantAnnouncementsReadCount(
                                                  0,
                                                  0,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF0284C7),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (!expanded) ...[
                                            const SizedBox(height: 10),
                                            Text(
                                              a.message,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF475569),
                                                height: 1.35,
                                              ),
                                            ),
                                          ],
                                          if (expanded) ...[
                                            const SizedBox(height: 12),
                                            const Divider(
                                              height: 1,
                                              color: Color(0xFFE2E8F0),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              a.message,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF334155),
                                                height: 1.35,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Text(
                                                  l10n.servantAnnouncementsTarget(
                                                    a.targetAudience,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  l10n.servantAnnouncementsStudentsReadCount(
                                                    0,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: -6,
                                right: -6,
                                child: IconButton(
                                  onPressed: () async {
                                    final ok = await _confirmDelete(
                                      context: context,
                                      title:
                                          l10n.servantAnnouncementsDeleteTitle,
                                      message:
                                          l10n.servantAnnouncementsDeleteBody,
                                      confirmLabel: l10n.commonDelete,
                                    );
                                    if (!ok) return;

                                    final deleted =
                                        await _deleteAnnouncementInBackend(
                                          a.id,
                                        );
                                    if (!mounted) return;

                                    if (!deleted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l10n.servantAnnouncementsDeleteFailed,
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() {
                                      _announcements.removeWhere(
                                        (x) => x.id == a.id,
                                      );
                                      if (_expandedAnnouncementId == a.id) {
                                        _expandedAnnouncementId = null;
                                      }
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFFEF4444),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ],
    );
  }

  Widget _buildQuestions() {
    final l10n = AppLocalizations.of(context);
    final subjects = <String>{..._questions.map((q) => q.subjectName)}.toList()
      ..sort();

    Widget statusChip({required String label, required String value}) {
      final selected = _questionStatusFilter == value;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() {
              _questionStatusFilter = value;
              _respondingQuestionId = null;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ),
        ),
      );
    }

    Iterable<_ServantQuestion> items = _questions;
    if (_questionStatusFilter == 'pending') {
      items = items.where((q) => !q.answered);
    } else if (_questionStatusFilter == 'answered') {
      items = items.where((q) => q.answered);
    }
    if (_questionSubjectFilter != 'all') {
      items = items.where((q) => q.subjectName == _questionSubjectFilter);
    }

    final list = items.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.commQuestions,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  statusChip(label: l10n.commonAll, value: 'all'),
                  statusChip(label: l10n.commPending, value: 'pending'),
                  statusChip(label: l10n.commAnswered, value: 'answered'),
                ],
              ),
              const SizedBox(height: 12),
              _ServantLabeledField(
                label: l10n.commSubjectLabel,
                child: _ServantDropdown(
                  value: _questionSubjectFilter,
                  items: ['all', ...subjects],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _questionSubjectFilter = v;
                      _respondingQuestionId = null;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_loadingQuestions)
          const Center(child: CircularProgressIndicator())
        else if (_questionsError != null)
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Failed to load questions.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _questionsError!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _loadQuestionsFromBackend,
                    child: Text(l10n.commonRetry),
                  ),
                ),
              ],
            ),
          )
        else if (list.isEmpty)
          _ServantEmptyState(
            icon: Icons.question_answer_rounded,
            title: l10n.commNoQuestionsYet,
            subtitle: l10n.commonTryChangingFilters,
          )
        else
          Column(
            children: list.map((q) {
              final isExpanded = _respondingQuestionId == q.id;
              final isPending = !q.answered;
              final statusPill = q.answered
                  ? _tinyPill(
                      label: l10n.commAnswered,
                      bg: const Color(0xFFD1FAE5),
                      fg: const Color(0xFF047857),
                    )
                  : _tinyPill(
                      label: l10n.commPending,
                      bg: const Color(0xFFFEF3C7),
                      fg: const Color(0xFF92400E),
                    );
              final dateLabel = EthiopianDateFormatter.formatFlexible(q.date);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPending
                          ? const Color(0xFFFDE68A)
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14374151),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 34),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  _tinyPill(
                                    label: q.subjectName,
                                    bg: const Color(0xFFE0F2FE),
                                    fg: const Color(0xFF0369A1),
                                  ),
                                  const Spacer(),
                                  statusPill,
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                q.studentName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                q.question,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              if (q.answered && q.answer != null && !isExpanded)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFD1FAE5,
                                      ).withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFD1FAE5),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.commResponseLabel,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF047857),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          q.answer!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF334155),
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (isPending && !isExpanded)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: SizedBox(
                                    height: 40,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _respondingQuestionId = q.id;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFF59E0B,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        l10n.servantCommRespond,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (isPending && isExpanded) ...[
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _questionControllerFor(q.id),
                                  minLines: 3,
                                  maxLines: 6,
                                  decoration: _inputDecoration(
                                    l10n.servantCommTypeResponseHint,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final reply = _questionControllerFor(
                                            q.id,
                                          ).text.trim();
                                          if (reply.isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  l10n.servantCommEnterResponseError,
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          final saved =
                                              await _answerQuestionInBackend(
                                                questionId: q.id,
                                                reply: reply,
                                              );
                                          if (!mounted) return;

                                          if (!saved) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Failed to send response. Please try again.',
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          setState(() {
                                            final index = _questions.indexWhere(
                                              (x) => x.id == q.id,
                                            );
                                            if (index != -1) {
                                              _questions[index] =
                                                  _questions[index].copyWith(
                                                    answered: true,
                                                    answer: reply,
                                                    answeredBy: 'You',
                                                    answeredDate: _todayIso(),
                                                  );
                                            }
                                            _questionControllerFor(
                                              q.id,
                                            ).clear();
                                            _respondingQuestionId = null;
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFF59E0B,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.send_rounded,
                                          size: 16,
                                        ),
                                        label: Text(
                                          l10n.servantCommSendResponse,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          _respondingQuestionId = null;
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF334155,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        l10n.commonCancel,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 10),
                              Text(
                                dateLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: IconButton(
                            onPressed: () async {
                              final ok = await _confirmDelete(
                                context: context,
                                title: l10n.servantCommDeleteQuestionTitle,
                                message: l10n.servantCommDeleteQuestionBody,
                                confirmLabel: l10n.commonDelete,
                              );
                              if (!ok) return;

                              final deleted = await _deleteQuestionInBackend(
                                q.id,
                              );
                              if (!mounted) return;

                              if (!deleted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.servantCommDeleteQuestionPermissionDenied,
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                _questions.removeWhere((x) => x.id == q.id);
                                if (_respondingQuestionId == q.id) {
                                  _respondingQuestionId = null;
                                }
                              });
                            },
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFEF4444),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildComplaints() {
    final l10n = AppLocalizations.of(context);
    Widget statusChip({required String label, required String value}) {
      final selected = _complaintStatusFilter == value;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() {
              _complaintStatusFilter = value;
              _respondingComplaintId = null;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ),
        ),
      );
    }

    Iterable<_ServantComplaint> items = _complaints;
    if (_complaintStatusFilter != 'all') {
      items = items.where((c) => c.status == _complaintStatusFilter);
    }
    if (_complaintCategoryFilter != 'all') {
      items = items.where((c) => c.category == _complaintCategoryFilter);
    }

    final list = items.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.commComplaints,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    statusChip(label: l10n.commonAll, value: 'all'),
                    const SizedBox(width: 8),
                    statusChip(label: l10n.commPending, value: 'pending'),
                    const SizedBox(width: 8),
                    statusChip(label: l10n.commInReview, value: 'in-review'),
                    const SizedBox(width: 8),
                    statusChip(label: l10n.commResolved, value: 'resolved'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ServantLabeledField(
                label: l10n.commCategoryLabel,
                child: _ServantDropdown(
                  value: _complaintCategoryFilter,
                  items: const [
                    'all',
                    'teaching',
                    'facility',
                    'administration',
                    'other',
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _complaintCategoryFilter = v;
                      _respondingComplaintId = null;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_loadingComplaints)
          const Center(child: CircularProgressIndicator())
        else if (_complaintsError != null)
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Failed to load complaints.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _complaintsError!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _loadComplaintsFromBackend,
                    child: Text(l10n.commonRetry),
                  ),
                ),
              ],
            ),
          )
        else if (list.isEmpty)
          _ServantEmptyState(
            icon: Icons.report_problem_rounded,
            title: l10n.servantCommNoComplaints,
            subtitle: l10n.commonTryChangingFilters,
          )
        else
          Column(
            children: list.map((c) {
              final isExpanded = _respondingComplaintId == c.id;
              final canRespond = c.status != 'resolved';
              final nextStatus =
                  _complaintNextStatus[c.id] ??
                  (c.status == 'pending' ? 'in-review' : c.status);

              final statusPill = _statusBadge(c.status, l10n);
              final categoryPill = _categoryBadge(c.category, l10n);
              final dateLabel = EthiopianDateFormatter.formatFlexible(c.date);
              final highlight = c.status != 'resolved';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: highlight
                          ? const Color(0xFFFECACA)
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14374151),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 34),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  categoryPill,
                                  const Spacer(),
                                  statusPill,
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                c.studentName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                c.complaint,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                  height: 1.35,
                                ),
                              ),
                              if (c.response != null && !isExpanded)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFD1FAE5,
                                      ).withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFD1FAE5),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.commResponseLabel,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF047857),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          c.response!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF334155),
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (!isExpanded && canRespond)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: SizedBox(
                                    height: 40,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _respondingComplaintId = c.id;
                                          _complaintNextStatus.putIfAbsent(
                                            c.id,
                                            () => c.status == 'pending'
                                                ? 'in-review'
                                                : c.status,
                                          );
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFF59E0B,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        l10n.servantCommRespond,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (isExpanded && canRespond) ...[
                                const SizedBox(height: 12),
                                _ServantLabeledField(
                                  label: l10n.commonStatus,
                                  child: _ServantDropdown(
                                    value: nextStatus,
                                    items: const [
                                      'pending',
                                      'in-review',
                                      'resolved',
                                    ],
                                    onChanged: (v) {
                                      if (v == null) return;
                                      setState(() {
                                        _complaintNextStatus[c.id] = v;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _complaintControllerFor(c.id),
                                  minLines: 3,
                                  maxLines: 6,
                                  decoration: _inputDecoration(
                                    l10n.servantCommTypeResponseHint,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final reply = _complaintControllerFor(
                                            c.id,
                                          ).text.trim();
                                          if (reply.isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  l10n.servantCommEnterResponseError,
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          final newStatus =
                                              _complaintNextStatus[c.id] ??
                                              c.status;

                                          final saved =
                                              await _updateComplaintInBackend(
                                                complaintId: c.id,
                                                reply: reply,
                                                newStatusUi: newStatus,
                                              );
                                          if (!mounted) return;

                                          if (!saved) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Failed to update complaint. Please try again.',
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          setState(() {
                                            final index = _complaints
                                                .indexWhere(
                                                  (x) => x.id == c.id,
                                                );
                                            if (index != -1) {
                                              _complaints[index] =
                                                  _complaints[index].copyWith(
                                                    response: reply,
                                                    respondedBy: 'You',
                                                    respondedDate: _todayIso(),
                                                    status: newStatus,
                                                  );
                                            }
                                            _complaintControllerFor(
                                              c.id,
                                            ).clear();
                                            _respondingComplaintId = null;
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFF59E0B,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.send_rounded,
                                          size: 16,
                                        ),
                                        label: Text(
                                          l10n.commonUpdate,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          _respondingComplaintId = null;
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF334155,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        l10n.commonCancel,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 10),
                              Text(
                                dateLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: IconButton(
                            onPressed: () async {
                              final ok = await _confirmDelete(
                                context: context,
                                title: l10n.servantCommDeleteComplaintTitle,
                                message: l10n.servantCommDeleteComplaintBody,
                                confirmLabel: l10n.commonDelete,
                              );
                              if (!ok) return;

                              final deleted = await _deleteComplaintInBackend(
                                c.id,
                              );
                              if (!mounted) return;

                              if (!deleted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.servantCommDeleteFromServerFailed,
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                _complaints.removeWhere((x) => x.id == c.id);
                                _complaintReplyControllers
                                    .remove(c.id)
                                    ?.dispose();
                                _complaintNextStatus.remove(c.id);
                                if (_respondingComplaintId == c.id) {
                                  _respondingComplaintId = null;
                                }
                              });
                            },
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFEF4444),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildFeedback() {
    if (_showCreateFeedback) {
      return _buildCreateFeedbackForm();
    }
    if (_viewingFeedbackFormId != null) {
      return _buildFeedbackAnalytics(_viewingFeedbackFormId!);
    }
    return _buildFeedbackTab();
  }

  _SubmissionRate _submissionRateFor(_ServantFeedbackForm form) {
    final total =
        form.targetStudents.isNotEmpty && form.targetStudents.first == 'all'
        ? (_totalStudentsInGrade ?? 0)
        : form.targetStudents.length;
    final submitted =
        _feedbackSubmissionCounts[form.id] ??
        _feedbackResponses.where((r) => r.formId == form.id).length;
    final percentage = total == 0 ? 0 : ((submitted / total) * 100).round();
    return _SubmissionRate(
      submitted: submitted,
      total: total,
      percentage: percentage,
    );
  }

  bool _isExpired(String endDateIso) {
    final end = DateTime.tryParse(endDateIso);
    if (end == null) return false;
    final now = DateTime.now();
    return end.isBefore(DateTime(now.year, now.month, now.day));
  }

  void _resetCreateFeedbackDraft() {
    _feedbackTitleController.clear();
    _feedbackDescriptionController.clear();
    _feedbackType = '';
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 14));
    _feedbackStartDate = _isoFromDate(start);
    _feedbackEndDate = _isoFromDate(end);
    _draftFeedbackQuestions.clear();
    _showAddFeedbackQuestion = false;
    _draftQuestionTextController.clear();
    _draftQuestionType = 'rating';
    _draftQuestionRequired = true;
    for (final c in _draftOptionControllers) {
      c.dispose();
    }
    _draftOptionControllers
      ..clear()
      ..add(TextEditingController());
  }

  static String _feedbackTypeLabel(AppLocalizations l10n, String type) {
    switch (type) {
      case 'teacher_evaluation':
        return l10n.servantFeedbackTypeTeacherEvaluation;
      case 'course_evaluation':
        return l10n.servantFeedbackTypeCourseEvaluation;
      case 'semester_evaluation':
        return l10n.servantFeedbackTypeSemesterEvaluation;
      case 'general':
        return l10n.servantFeedbackTypeGeneral;
      default:
        return type.replaceAll('_', ' ');
    }
  }

  static String _feedbackQuestionTypeLabel(
    AppLocalizations l10n,
    String questionType,
  ) {
    switch (questionType) {
      case 'rating':
        return l10n.servantFeedbackQuestionTypeRating;
      case 'text':
        return l10n.servantFeedbackQuestionTypeText;
      case 'multiple_choice':
        return l10n.servantFeedbackQuestionTypeMultipleChoice;
      default:
        return questionType.replaceAll('_', ' ');
    }
  }

  static String _isoFromDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickFeedbackType() async {
    final l10n = AppLocalizations.of(context);
    final types = const [
      'teacher_evaluation',
      'course_evaluation',
      'semester_evaluation',
      'general',
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Text(
                  l10n.servantFeedbackSelectTypeTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              ...types.map((t) {
                return ListTile(
                  title: Text(
                    _feedbackTypeLabel(l10n, t),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop(t),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected == null) return;
    setState(() {
      _feedbackType = selected;
    });
  }

  Future<void> _pickFeedbackDate({required bool isStart}) async {
    final currentIso = isStart ? _feedbackStartDate : _feedbackEndDate;
    final parsed = DateTime.tryParse(currentIso);
    final now = DateTime.now();
    final initial = parsed ?? DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
    );

    if (picked == null) return;
    setState(() {
      final iso = _isoFromDate(picked);
      if (isStart) {
        _feedbackStartDate = iso;
      } else {
        _feedbackEndDate = iso;
      }
    });
  }

  Widget _buildFeedbackTab() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _showCreateFeedback = true;
              _viewingFeedbackFormId = null;
              _resetCreateFeedbackDraft();
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
          ),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(
            l10n.servantFeedbackCreateFormButton,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 14),
        if (_loadingFeedback)
          const Center(child: CircularProgressIndicator())
        else if (_feedbackError != null)
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Failed to load feedback forms.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _feedbackError!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _loadFeedbackFromBackend,
                    child: Text(l10n.commonRetry),
                  ),
                ),
              ],
            ),
          )
        else if (_feedbackForms.isEmpty)
          _ServantEmptyState(
            icon: Icons.fact_check_rounded,
            title: l10n.servantFeedbackEmptyTitle,
            subtitle: l10n.servantFeedbackEmptySubtitle,
          )
        else ...[
          Text(
            l10n.servantFeedbackActiveFormsLabel,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Column(
            children: _feedbackForms.map((form) {
              final expired = _isExpired(form.endDate);
              final rate = _submissionRateFor(form);

              final statusPill = expired
                  ? _tinyPill(
                      label: l10n.servantFeedbackStatusExpired,
                      bg: const Color(0xFFFEE2E2),
                      fg: const Color(0xFFB91C1C),
                    )
                  : _tinyPill(
                      label: l10n.servantFeedbackStatusActive,
                      bg: const Color(0xFFD1FAE5),
                      fg: const Color(0xFF047857),
                    );

              return Opacity(
                opacity: expired ? 0.75 : 1,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Row(
                                children: [statusPill, const Spacer()],
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  l10n.servantFeedbackQuestionsCount(
                                    form.questions.length,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  onPressed: () async {
                                    final ok = await _confirmDelete(
                                      context: context,
                                      title:
                                          l10n.servantFeedbackDeleteFormTitle,
                                      message: l10n
                                          .servantFeedbackDeleteFormBody(
                                            rate.submitted,
                                          ),
                                      confirmLabel: l10n.commonDelete,
                                    );
                                    if (!ok) return;

                                    final deleted =
                                        await _deleteFeedbackFormInBackend(
                                          form.id,
                                        );
                                    if (!mounted) return;

                                    if (!deleted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Failed to delete feedback form.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() {
                                      _feedbackForms.removeWhere(
                                        (f) => f.id == form.id,
                                      );
                                      _feedbackResponses.removeWhere(
                                        (r) => r.formId == form.id,
                                      );
                                      _feedbackSubmissionCounts.remove(form.id);
                                      if (_viewingFeedbackFormId == form.id) {
                                        _viewingFeedbackFormId = null;
                                      }
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: Color(0xFFEF4444),
                                  ),
                                  tooltip: l10n.commonDelete,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          form.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          form.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.servantFeedbackDueLabel(
                                  EthiopianDateFormatter.formatFlexible(
                                    form.endDate,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: expired
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            Text(
                              l10n.servantFeedbackResponsesCount(
                                rate.submitted,
                                rate.total,
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF0284C7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _viewingFeedbackFormId = form.id;
                              _showCreateFeedback = false;
                            });
                            _loadFeedbackResponsesForForm(form.id);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0EA5E9),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.remove_red_eye_rounded,
                            size: 18,
                          ),
                          label: Text(
                            l10n.servantFeedbackViewAnalyticsButton,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ignore: unused_element
  Widget _buildFeedbackListOnly() {
    return _buildFeedbackTab();
  }

  Widget _buildCreateFeedbackForm() {
    final l10n = AppLocalizations.of(context);
    InputDecoration feedbackInputDecoration(String hint) {
      return InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2),
        ),
      );
    }

    Widget datePill({
      required String label,
      required String value,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 18,
                color: Color(0xFF0EA5E9),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0EA5E9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0369A1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.servantFeedbackCreateFormTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          _ServantLabeledField(
            label: l10n.servantFeedbackTitleLabel,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _feedbackTitleController,
              builder: (context, value, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _feedbackTitleController,
                      maxLength: 100,
                      decoration: feedbackInputDecoration(
                        l10n.servantFeedbackTitleHint,
                      ).copyWith(counterText: ''),
                    ),
                    Text(
                      '${value.text.length}/100',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _ServantLabeledField(
            label: l10n.servantFeedbackDescriptionLabel,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _feedbackDescriptionController,
              builder: (context, value, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _feedbackDescriptionController,
                      maxLength: 300,
                      minLines: 3,
                      maxLines: 6,
                      decoration: feedbackInputDecoration(
                        l10n.servantFeedbackDescriptionHint,
                      ).copyWith(counterText: ''),
                    ),
                    Text(
                      '${value.text.length}/300',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _ServantLabeledField(
            label: l10n.servantFeedbackTypeLabel,
            child: InkWell(
              onTap: _pickFeedbackType,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF0EA5E9), width: 2),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _feedbackType.isEmpty
                            ? l10n.servantFeedbackSelectTypeTitle
                            : _feedbackTypeLabel(l10n, _feedbackType),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _feedbackType.isEmpty
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: datePill(
                  label: l10n.servantFeedbackStartDateLabel,
                  value: EthiopianDateFormatter.formatFlexible(
                    _feedbackStartDate,
                  ),
                  onTap: () => _pickFeedbackDate(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: datePill(
                  label: l10n.servantFeedbackEndDateLabel,
                  value: EthiopianDateFormatter.formatFlexible(
                    _feedbackEndDate,
                  ),
                  onTap: () => _pickFeedbackDate(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.servantFeedbackQuestionsSectionTitle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.servantFeedbackQuestionsAddedCount(
                              _draftFeedbackQuestions.length,
                            ),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _showAddFeedbackQuestion = true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(
                        l10n.servantFeedbackAddQuestionButton,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                if (_draftFeedbackQuestions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Column(
                    children: _draftFeedbackQuestions.asMap().entries.map((e) {
                      final index = e.key;
                      final q = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _tinyPill(
                                          label: l10n.commonQuestionShort(
                                            index + 1,
                                          ),
                                          bg: const Color(0xFFFEF3C7),
                                          fg: const Color(0xFF92400E),
                                        ),
                                        _tinyPill(
                                          label: _feedbackQuestionTypeLabel(
                                            l10n,
                                            q.type,
                                          ),
                                          bg: const Color(0xFFE2E8F0),
                                          fg: const Color(0xFF475569),
                                        ),
                                        if (q.required)
                                          _tinyPill(
                                            label: l10n
                                                .servantFeedbackRequiredLabel,
                                            bg: const Color(0xFFFEE2E2),
                                            fg: const Color(0xFFB91C1C),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      q.question,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    if (q.type == 'multiple_choice' &&
                                        q.options.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      ...q.options.map(
                                        (o) => Padding(
                                          padding: const EdgeInsets.only(
                                            left: 10,
                                            bottom: 2,
                                          ),
                                          child: Text(
                                            '• $o',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _draftFeedbackQuestions.removeAt(index);
                                  });
                                },
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (_showAddFeedbackQuestion) ...[
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFBAE6FD),
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.servantFeedbackNewQuestionTitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0C4A6E),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _showAddFeedbackQuestion = false;
                                  _draftQuestionTextController.clear();
                                  _draftQuestionType = 'rating';
                                  _draftQuestionRequired = true;
                                  for (final c in _draftOptionControllers) {
                                    c.dispose();
                                  }
                                  _draftOptionControllers
                                    ..clear()
                                    ..add(TextEditingController());
                                });
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Color(0xFF0369A1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _ServantLabeledField(
                          label: l10n.servantFeedbackQuestionTextLabel,
                          child: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _draftQuestionTextController,
                            builder: (context, value, _) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: _draftQuestionTextController,
                                    maxLength: 200,
                                    minLines: 2,
                                    maxLines: 4,
                                    decoration: _inputDecoration(
                                      l10n.servantFeedbackQuestionTextHint,
                                    ).copyWith(counterText: ''),
                                  ),
                                  Text(
                                    '${value.text.length}/200',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _ServantLabeledField(
                                label: l10n.servantFeedbackQuestionTypeLabel,
                                child: _ServantDropdown(
                                  value: _draftQuestionType,
                                  items: const [
                                    'rating',
                                    'text',
                                    'multiple_choice',
                                  ],
                                  labelBuilder: (v) =>
                                      _feedbackQuestionTypeLabel(l10n, v),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() {
                                      _draftQuestionType = v;
                                      if (v != 'multiple_choice') {
                                        for (final c
                                            in _draftOptionControllers) {
                                          c.dispose();
                                        }
                                        _draftOptionControllers
                                          ..clear()
                                          ..add(TextEditingController());
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ServantLabeledField(
                                label:
                                    l10n.servantFeedbackRequiredQuestionLabel,
                                child: _ServantDropdown(
                                  value: _draftQuestionRequired ? 'yes' : 'no',
                                  items: const ['yes', 'no'],
                                  labelBuilder: (v) {
                                    if (v == 'yes') {
                                      return l10n.servantFeedbackYes;
                                    }
                                    if (v == 'no') {
                                      return l10n.servantFeedbackNo;
                                    }
                                    return v;
                                  },
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setState(() {
                                      _draftQuestionRequired = v == 'yes';
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_draftQuestionType == 'multiple_choice') ...[
                          const SizedBox(height: 12),
                          Text(
                            l10n.servantFeedbackOptionsLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: _draftOptionControllers
                                .asMap()
                                .entries
                                .map((e) {
                                  final index = e.key;
                                  final controller = e.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: controller,
                                            decoration: _inputDecoration(
                                              l10n.servantFeedbackOptionHint(
                                                index + 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (_draftOptionControllers.length > 1)
                                          IconButton(
                                            onPressed: () {
                                              setState(() {
                                                final removed =
                                                    _draftOptionControllers
                                                        .removeAt(index);
                                                removed.dispose();
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              size: 18,
                                              color: Color(0xFFEF4444),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _draftOptionControllers.add(
                                  TextEditingController(),
                                );
                              });
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0284C7),
                              padding: EdgeInsets.zero,
                            ),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: Text(
                              l10n.servantFeedbackAddOptionButton,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final text = _draftQuestionTextController.text
                                      .trim();
                                  if (text.isEmpty) return;

                                  final options =
                                      _draftQuestionType == 'multiple_choice'
                                      ? _draftOptionControllers
                                            .map((c) => c.text.trim())
                                            .where((o) => o.isNotEmpty)
                                            .toList()
                                      : <String>[];

                                  if (_draftQuestionType == 'multiple_choice' &&
                                      options.length < 2) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.servantFeedbackMultipleChoiceNeedsTwoOptions,
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() {
                                    _draftFeedbackQuestions.add(
                                      _DraftFeedbackQuestion(
                                        id: DateTime.now()
                                            .millisecondsSinceEpoch
                                            .toString(),
                                        question: text,
                                        type: _draftQuestionType,
                                        required: _draftQuestionRequired,
                                        options: options,
                                      ),
                                    );
                                    _draftQuestionTextController.clear();
                                    _draftQuestionType = 'rating';
                                    _draftQuestionRequired = true;
                                    for (final c in _draftOptionControllers) {
                                      c.dispose();
                                    }
                                    _draftOptionControllers
                                      ..clear()
                                      ..add(TextEditingController());
                                    _showAddFeedbackQuestion = false;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0EA5E9),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  l10n.servantFeedbackAddQuestionButton,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _showAddFeedbackQuestion = false;
                                  _draftQuestionTextController.clear();
                                  _draftQuestionType = 'rating';
                                  _draftQuestionRequired = true;
                                  for (final c in _draftOptionControllers) {
                                    c.clear();
                                  }
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF334155),
                                side: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(context).commonCancel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final l10n = AppLocalizations.of(context);
                    final title = _feedbackTitleController.text.trim();
                    final desc = _feedbackDescriptionController.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.servantFeedbackEnterTitleError),
                        ),
                      );
                      return;
                    }
                    if (desc.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.servantFeedbackEnterDescriptionError,
                          ),
                        ),
                      );
                      return;
                    }
                    if (_draftFeedbackQuestions.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.servantFeedbackAddAtLeastOneQuestionError,
                          ),
                        ),
                      );
                      return;
                    }

                    final start = DateTime.tryParse(_feedbackStartDate);
                    final end = DateTime.tryParse(_feedbackEndDate);
                    if (start == null || end == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.servantFeedbackValidDatesError),
                        ),
                      );
                      return;
                    }
                    if (!end.isAfter(start)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.servantFeedbackEndAfterStartError),
                        ),
                      );
                      return;
                    }
                    if (_feedbackType.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.servantFeedbackSelectTypeError),
                        ),
                      );
                      return;
                    }

                    final questions = _draftFeedbackQuestions
                        .asMap()
                        .entries
                        .map(
                          (e) => _ServantFeedbackQuestion(
                            id: 'q${e.key + 1}',
                            question: e.value.question,
                            type: e.value.type,
                            required: e.value.required,
                            options: e.value.options,
                          ),
                        )
                        .toList();

                    _ServantFeedbackForm? created;
                    try {
                      created = await _createFeedbackFormInBackend(
                        title: title,
                        description: desc,
                        typeLabel: _feedbackType,
                        startDateIso: _feedbackStartDate,
                        endDateIso: _feedbackEndDate,
                        questions: questions,
                      );
                    } catch (_) {
                      created = null;
                    }

                    if (!mounted) return;

                    if (created == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Failed to create feedback form. Please try again.',
                          ),
                        ),
                      );
                      return;
                    }

                    await _loadFeedbackFromBackend();
                    if (!mounted) return;

                    setState(() {
                      _showFeedbackSuccessToast = true;
                    });

                    Future.delayed(const Duration(milliseconds: 1500), () {
                      if (!mounted) return;
                      setState(() {
                        _showFeedbackSuccessToast = false;
                        _showCreateFeedback = false;
                      });
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.servantFeedbackCreateFormSubmitButton,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _showCreateFeedback = false;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.commonCancel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackAnalytics(String formId) {
    final l10n = AppLocalizations.of(context);
    final formIndex = _feedbackForms.indexWhere((f) => f.id == formId);
    if (formIndex == -1) {
      return _ServantEmptyState(
        icon: Icons.error_outline_rounded,
        title: l10n.servantFeedbackFormNotFoundTitle,
        subtitle: l10n.servantFeedbackFormNotFoundSubtitle,
      );
    }

    final form = _feedbackForms[formIndex];

    final responses = _feedbackResponses
        .where((r) => r.formId == formId)
        .toList();
    final rate = _submissionRateFor(form);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.servantFeedbackAnalyticsTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _viewingFeedbackFormId = null);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64748B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: Text(
                l10n.commonBack,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          form.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          form.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _tinyPill(
                    label: _isExpired(form.endDate)
                        ? l10n.servantFeedbackStatusExpired
                        : l10n.servantFeedbackStatusActive,
                    bg: _isExpired(form.endDate)
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFD1FAE5),
                    fg: _isExpired(form.endDate)
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF047857),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l10n.servantFeedbackQuestionsAndDueLine(
                  form.questions.length,
                  EthiopianDateFormatter.formatFlexible(form.endDate),
                ),
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bar_chart_rounded,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.servantFeedbackSubmissionStatisticsTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AnalyticsStat(
                      value: '${rate.submitted}',
                      valueColor: const Color(0xFF16A34A),
                      label: l10n.servantFeedbackSubmittedLabel,
                    ),
                  ),
                  Expanded(
                    child: _AnalyticsStat(
                      value: '${rate.total - rate.submitted}',
                      valueColor: const Color(0xFFD97706),
                      label: l10n.servantFeedbackPendingLabel,
                    ),
                  ),
                  Expanded(
                    child: _AnalyticsStat(
                      value: '${rate.percentage}%',
                      valueColor: const Color(0xFF0284C7),
                      label: l10n.servantFeedbackRateLabel,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_loadingFeedbackResponses)
          const Center(child: CircularProgressIndicator())
        else if (_feedbackResponsesError != null)
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Failed to load responses.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _feedbackResponsesError!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => _loadFeedbackResponsesForForm(formId),
                    child: Text(l10n.commonRetry),
                  ),
                ),
              ],
            ),
          )
        else if (responses.isEmpty)
          _buildSectionCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: _ServantEmptyState(
                icon: Icons.fact_check_rounded,
                title: l10n.servantFeedbackNoResponsesTitle,
                subtitle: l10n.servantFeedbackNoResponsesSubtitle,
              ),
            ),
          )
        else
          Column(
            children: form.questions.asMap().entries.map((e) {
              final index = e.key;
              final question = e.value;
              final responseCount = responses.where((r) {
                final answer = r.answers[question.id];
                if (answer == null) return false;
                if (answer is String) return answer.trim().isNotEmpty;
                if (answer is List) return answer.isNotEmpty;
                return true;
              }).length;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _tinyPill(
                            label: l10n.commonQuestionShort(index + 1),
                            bg: const Color(0xFFE0F2FE),
                            fg: const Color(0xFF0369A1),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  question.question,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.servantFeedbackResponsesCountLabel(
                                    responseCount,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (question.type == 'rating')
                        _buildRatingAnalytics(question, responses)
                      else if (question.type == 'multiple_choice')
                        _buildMultipleChoiceAnalytics(question, responses)
                      else
                        _buildTextAnalytics(question, responses),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildRatingAnalytics(
    _ServantFeedbackQuestion question,
    List<_ServantFeedbackResponse> responses,
  ) {
    final l10n = AppLocalizations.of(context);
    final ratings = responses
        .map((r) => r.answers[question.id])
        .whereType<num>()
        .map((n) => n.toInt())
        .where((n) => n >= 1 && n <= 5)
        .toList();

    final avg = ratings.isEmpty
        ? 0
        : (ratings.reduce((a, b) => a + b) / ratings.length);
    final rounded = avg.round().clamp(0, 5);

    final distribution = List.generate(5, (i) {
      final rating = i + 1;
      final count = ratings.where((r) => r == rating).length;
      final percent = ratings.isEmpty
          ? 0
          : ((count / ratings.length) * 100).round();
      return (rating: rating, count: count, percent: percent);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.servantFeedbackAverageRatingLabel,
                style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    avg.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i + 1 <= rounded;
                      return Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: filled
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFE2E8F0),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.servantFeedbackDistributionLabel,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 8),
        Column(
          children: distribution.map((d) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${d.rating}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 22,
                        color: const Color(0xFFE2E8F0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: d.percent / 100,
                            child: Container(color: const Color(0xFFF59E0B)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 66,
                    child: Text(
                      '${d.count} (${d.percent}%)',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMultipleChoiceAnalytics(
    _ServantFeedbackQuestion question,
    List<_ServantFeedbackResponse> responses,
  ) {
    final answers = responses
        .map((r) => r.answers[question.id])
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();

    final total = answers.length;
    final optionCounts = question.options.map((o) {
      final count = answers.where((a) => a == o).length;
      final percent = total == 0 ? 0 : ((count / total) * 100).round();
      return (option: o, count: count, percent: percent);
    }).toList();

    return Column(
      children: optionCounts.map((o) {
        final showInside = o.percent > 15;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      o.option,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 22,
                        color: const Color(0xFFE2E8F0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: o.percent / 100,
                            child: Container(
                              color: const Color(0xFF0EA5E9),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 8),
                              child: showInside
                                  ? Text(
                                      '${o.count} (${o.percent}%)',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!showInside) ...[
                const SizedBox(width: 10),
                SizedBox(
                  width: 66,
                  child: Text(
                    '${o.count} (${o.percent}%)',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextAnalytics(
    _ServantFeedbackQuestion question,
    List<_ServantFeedbackResponse> responses,
  ) {
    final l10n = AppLocalizations.of(context);
    final texts = responses
        .map((r) => r.answers[question.id])
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.servantFeedbackTextResponsesReceived(texts.length),
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(maxHeight: 240),
          child: SingleChildScrollView(
            child: Column(
              children: texts.map((t) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '"$t"',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF334155),
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF59E0B)),
      ),
    );
  }

  static String _todayIso() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // ignore: unused_element
  static String _truncate(String text, int max) {
    if (text.length <= max) return text;
    return '${text.substring(0, max).trimRight()}…';
  }

  static Widget _tinyPill({
    required String label,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  static Widget _categoryBadge(String category, AppLocalizations l10n) {
    switch (category) {
      case 'urgent':
        return _tinyPill(
          label: l10n.commAnnouncementCategoryUrgent,
          bg: const Color(0xFFFEE2E2),
          fg: const Color(0xFFB91C1C),
        );
      case 'grades':
        return _tinyPill(
          label: l10n.commAnnouncementCategoryGrades,
          bg: const Color(0xFFFEF3C7),
          fg: const Color(0xFF92400E),
        );
      case 'schedule':
        return _tinyPill(
          label: l10n.commAnnouncementCategorySchedule,
          bg: const Color(0xFFDBEAFE),
          fg: const Color(0xFF1D4ED8),
        );
      case 'event':
        return _tinyPill(
          label: l10n.commAnnouncementCategoryEvent,
          bg: const Color(0xFFD1FAE5),
          fg: const Color(0xFF047857),
        );
      case 'teaching':
        return _tinyPill(
          label: l10n.commCategoryTeacher,
          bg: const Color(0xFFE0F2FE),
          fg: const Color(0xFF0369A1),
        );
      case 'facility':
        return _tinyPill(
          label: l10n.commCategoryFacility,
          bg: const Color(0xFFFEF3C7),
          fg: const Color(0xFF92400E),
        );
      case 'administration':
        return _tinyPill(
          label: l10n.commCategoryAdministrative,
          bg: const Color(0xFFE2E8F0),
          fg: const Color(0xFF475569),
        );
      case 'other':
        return _tinyPill(
          label: l10n.commCategoryOther,
          bg: const Color(0xFFF1F5F9),
          fg: const Color(0xFF475569),
        );
      default:
        return _tinyPill(
          label: category,
          bg: const Color(0xFFF1F5F9),
          fg: const Color(0xFF475569),
        );
    }
  }

  // ignore: unused_element
  static Widget _priorityBadge(String priority, AppLocalizations l10n) {
    switch (priority) {
      case 'high':
        return _tinyPill(
          label: l10n.commonHigh,
          bg: const Color(0xFFFEE2E2),
          fg: const Color(0xFFB91C1C),
        );
      case 'medium':
        return _tinyPill(
          label: l10n.commonMedium,
          bg: const Color(0xFFFEF3C7),
          fg: const Color(0xFF92400E),
        );
      case 'low':
      default:
        return _tinyPill(
          label: l10n.commonLow,
          bg: const Color(0xFFF1F5F9),
          fg: const Color(0xFF475569),
        );
    }
  }

  static Widget _statusBadge(String status, AppLocalizations l10n) {
    switch (status) {
      case 'pending':
        return _tinyPill(
          label: l10n.commPending,
          bg: const Color(0xFFFEE2E2),
          fg: const Color(0xFFB91C1C),
        );
      case 'in-review':
        return _tinyPill(
          label: l10n.commInReview,
          bg: const Color(0xFFFEF3C7),
          fg: const Color(0xFF92400E),
        );
      case 'resolved':
        return _tinyPill(
          label: l10n.commResolved,
          bg: const Color(0xFFD1FAE5),
          fg: const Color(0xFF047857),
        );
      default:
        return _tinyPill(
          label: status,
          bg: const Color(0xFFF1F5F9),
          fg: const Color(0xFF475569),
        );
    }
  }
}

enum _ServantBadgeStyle { amber, red }

class _ServantCommTabButton extends StatelessWidget {
  const _ServantCommTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    this.badgeCount,
    this.badgeStyle,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final int? badgeCount;
  final _ServantBadgeStyle? badgeStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? const Color(0xFFD97706)
        : const Color(0xFF64748B); // amber-600 vs slate-500

    final showBadge = (badgeCount ?? 0) > 0;

    Color badgeBg = const Color(0xFFFEF3C7);
    Color badgeFg = const Color(0xFF92400E);
    if (badgeStyle == _ServantBadgeStyle.red) {
      badgeBg = const Color(0xFFFEE2E2);
      badgeFg = const Color(0xFFB91C1C);
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFFD97706) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
            if (showBadge) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${badgeCount!}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeFg,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ServantLabeledField extends StatelessWidget {
  const _ServantLabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _ServantDropdown extends StatelessWidget {
  const _ServantDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelBuilder,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final String Function(String value)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded),
          items: items
              .map(
                (i) => DropdownMenuItem<String>(
                  value: i,
                  child: Text(
                    (labelBuilder == null) ? i : labelBuilder!(i),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ServantEmptyState extends StatelessWidget {
  const _ServantEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        children: [
          Icon(icon, size: 44, color: const Color(0xFFE2E8F0)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

class _ServantAnnouncement {
  const _ServantAnnouncement({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.createdBy,
    required this.createdDate,
    required this.priority,
    required this.targetAudience,
    this.expiresOn,
  });

  final String id;
  final String title;
  final String message;
  final String category;
  final String createdBy;
  final String createdDate;
  final String priority;
  final String targetAudience;
  final String? expiresOn;
}

class _ServantQuestion {
  const _ServantQuestion({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.subjectId,
    required this.subjectName,
    required this.question,
    required this.date,
    required this.answered,
    this.answer,
    this.answeredBy,
    this.answeredDate,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String subjectId;
  final String subjectName;
  final String question;
  final String date;
  final bool answered;
  final String? answer;
  final String? answeredBy;
  final String? answeredDate;

  _ServantQuestion copyWith({
    bool? answered,
    String? answer,
    String? answeredBy,
    String? answeredDate,
  }) {
    return _ServantQuestion(
      id: id,
      studentId: studentId,
      studentName: studentName,
      subjectId: subjectId,
      subjectName: subjectName,
      question: question,
      date: date,
      answered: answered ?? this.answered,
      answer: answer ?? this.answer,
      answeredBy: answeredBy ?? this.answeredBy,
      answeredDate: answeredDate ?? this.answeredDate,
    );
  }
}

class _ServantComplaint {
  const _ServantComplaint({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.complaint,
    required this.category,
    required this.date,
    required this.status,
    this.response,
    this.respondedBy,
    this.respondedDate,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String complaint;
  final String category;
  final String date;
  final String status;
  final String? response;
  final String? respondedBy;
  final String? respondedDate;

  _ServantComplaint copyWith({
    String? status,
    String? response,
    String? respondedBy,
    String? respondedDate,
  }) {
    return _ServantComplaint(
      id: id,
      studentId: studentId,
      studentName: studentName,
      complaint: complaint,
      category: category,
      date: date,
      status: status ?? this.status,
      response: response ?? this.response,
      respondedBy: respondedBy ?? this.respondedBy,
      respondedDate: respondedDate ?? this.respondedDate,
    );
  }
}

class _DraftFeedbackQuestion {
  const _DraftFeedbackQuestion({
    required this.id,
    required this.question,
    required this.type,
    required this.required,
    this.options = const [],
  });

  final String id;
  final String question;
  final String type; // rating | text | multiple_choice
  final bool required;
  final List<String> options;
}

class _ServantFeedbackQuestion {
  const _ServantFeedbackQuestion({
    required this.id,
    required this.question,
    required this.type,
    required this.required,
    this.options = const [],
  });

  final String id;
  final String question;
  final String type; // rating | text | multiple_choice
  final bool required;
  final List<String> options;
}

class _SubmissionRate {
  const _SubmissionRate({
    required this.submitted,
    required this.total,
    required this.percentage,
  });

  final int submitted;
  final int total;
  final int percentage;
}

class _AnalyticsStat extends StatelessWidget {
  const _AnalyticsStat({
    required this.value,
    required this.valueColor,
    required this.label,
  });

  final String value;
  final Color valueColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

class _ServantFeedbackForm {
  const _ServantFeedbackForm({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.createdBy,
    required this.createdDate,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.targetStudents,
    required this.questions,
  });

  final String id;
  final String title;
  final String description;
  final String type;
  final String createdBy;
  final String createdDate;
  final String startDate;
  final String endDate;
  final String status;
  final List<String> targetStudents;
  final List<_ServantFeedbackQuestion> questions;
}

class _ServantFeedbackResponse {
  const _ServantFeedbackResponse({
    required this.id,
    required this.formId,
    required this.studentId,
    required this.studentName,
    required this.submittedDate,
    required this.answers,
  });

  final String id;
  final String formId;
  final String studentId;
  final String studentName;
  final String submittedDate;
  final Map<String, Object?> answers;
}

class ServantProfileScreen extends StatefulWidget {
  const ServantProfileScreen({super.key});

  @override
  State<ServantProfileScreen> createState() => _ServantProfileScreenState();
}

class _ProfileData {
  const _ProfileData({
    required this.academicId,
    required this.role,
    required this.accountStatus,
    this.name,
    this.gradeName,
    this.gradeCode,
    this.email,
  });

  final String academicId;
  final String? name;
  final String role;
  final String accountStatus;
  final String? gradeName;
  final String? gradeCode;
  final String? email;
}

class _ServantProfileScreenState extends State<ServantProfileScreen> {
  late Future<_ProfileData> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<_ProfileData> _loadProfile() async {
    final client = SupabaseClientManager.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('not_signed_in');
    }

    final profile = await client
        .from('profiles')
        .select('academic_id, name, role, grade_id, account_status')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      throw StateError('profile_not_found');
    }

    final gradeId = (profile as Map)['grade_id']?.toString();
    String? gradeName;
    String? gradeCode;
    if (gradeId != null && gradeId.isNotEmpty) {
      final grade = await client
          .from('grades')
          .select('name, code')
          .eq('id', gradeId)
          .maybeSingle();
      gradeName = (grade as Map?)?['name']?.toString();
      gradeCode = (grade as Map?)?['code']?.toString();
    }

    return _ProfileData(
      academicId: (profile as Map)['academic_id']?.toString() ?? '',
      name: profile['name']?.toString(),
      role: profile['role']?.toString() ?? 'servant',
      accountStatus: profile['account_status']?.toString() ?? 'active',
      gradeName: gradeName,
      gradeCode: gradeCode,
      email: user.email,
    );
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _profileFuture = _loadProfile();
    });
    await _profileFuture;
  }

  Future<void> _signOut() async {
    final client = SupabaseClientManager.instance.client;
    await PushNotificationsService.instance.unregisterBeforeSignOut();
    await client.auth.signOut();
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFD97706); // amber-600
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: AppRefreshConfigurator(
          onRefresh: _handleRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.navProfile,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.profileAccountDetailsSubtitle,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFFFDE68A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: FutureBuilder<_ProfileData>(
                  future: _profileFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      final error = snapshot.error;
                      var errorText = error.toString();
                      if (error is StateError) {
                        final msg = error.message;
                        if (msg == 'not_signed_in') {
                          errorText = l10n.profileErrorNotSignedIn;
                        } else if (msg == 'profile_not_found') {
                          errorText = l10n.profileErrorNotFound;
                        }
                      }
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14374151),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.profileLoadFailedTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              errorText,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _handleRefresh,
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(l10n.commonRetry),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final data = snapshot.data;
                    if (data == null) {
                      return const SizedBox.shrink();
                    }

                    final displayName =
                        (data.name == null || data.name!.trim().isEmpty)
                        ? l10n.roleServant
                        : data.name!.trim();
                    final gradeText =
                        (data.gradeName == null || data.gradeName!.isEmpty)
                        ? l10n.profileNotAssigned
                        : (data.gradeCode == null || data.gradeCode!.isEmpty)
                        ? data.gradeName!
                        : '${data.gradeName} (${data.gradeCode})';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14374151),
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: accent,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          data.email ?? '',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.badge_outlined,
                                  color: accent,
                                ),
                                title: Text(l10n.profileAcademicIdLabel),
                                subtitle: Text(data.academicId),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.class_outlined,
                                  color: accent,
                                ),
                                title: Text(l10n.profileGradeLabel),
                                subtitle: Text(gradeText),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.verified_user_outlined,
                                  color: accent,
                                ),
                                title: Text(l10n.profileAccountStatusLabel),
                                subtitle: Text(data.accountStatus),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.work_outline,
                                  color: accent,
                                ),
                                title: Text(l10n.profileRoleLabel),
                                subtitle: Text(data.role),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _signOut,
                          icon: const Icon(Icons.logout_rounded),
                          label: Text(l10n.commonSignOut),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

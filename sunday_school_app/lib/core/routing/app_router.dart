import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/access_denied_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/student/presentation/student_screens.dart';
import '../../features/servant/presentation/analytics/servant_analytics_screen.dart';
import '../../features/servant/presentation/servant_screens.dart';
import '../bootstrap/app_bootstrap.dart';
import '../bootstrap/bootstrap_error_screen.dart';
import '../splash/splash_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class _CachedUserProfile {
  const _CachedUserProfile({this.role, this.accountStatus});

  final String? role;
  final String? accountStatus;
}

String? _cachedProfileUserId;
_CachedUserProfile _cachedProfile = const _CachedUserProfile();
bool _cachedProfileLoaded = false;
Future<void>? _profileFetchInProgress;

void clearCachedUserProfile() {
  _clearProfileCache();
}

void _clearProfileCache() {
  _cachedProfileUserId = null;
  _cachedProfile = const _CachedUserProfile();
  _cachedProfileLoaded = false;
  _profileFetchInProgress = null;
}

Future<_CachedUserProfile?> _resolveCurrentUserProfile() async {
  String? userId;
  try {
    userId = Supabase.instance.client.auth.currentUser?.id;
  } catch (_) {
    return null;
  }

  if (userId == null) {
    _clearProfileCache();
    return null;
  }

  final resolvedUserId = userId;

  if (_cachedProfileUserId != resolvedUserId) {
    _clearProfileCache();
    _cachedProfileUserId = resolvedUserId;
  }

  if (_cachedProfileLoaded) return _cachedProfile;

  final inProgress = _profileFetchInProgress;
  if (inProgress != null) {
    await inProgress;
    return _cachedProfile;
  }

  final fetch = _profileFetchInProgress = () async {
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role, account_status')
          .eq('id', resolvedUserId)
          .maybeSingle();

      _cachedProfile = _CachedUserProfile(
        role: profile?['role']?.toString().trim().toLowerCase(),
        accountStatus: profile?['account_status']
            ?.toString()
            .trim()
            .toLowerCase(),
      );
    } catch (_) {
      _cachedProfile = const _CachedUserProfile();
    } finally {
      _cachedProfileLoaded = true;
      _profileFetchInProgress = null;
    }
  }();

  await fetch;
  return _cachedProfile;
}

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) async {
    final path = state.uri.path;

    // Hold users on the splash screen until bootstrap finishes (the profile
    // fetch below then runs while the splash is still mounted), and surface
    // fatal bootstrap failures on the error screen.
    final bootstrap = AppBootstrap.instance;
    if (bootstrap.status == AppBootstrapStatus.initializing) {
      return path == '/splash' ? null : '/splash';
    }
    if (bootstrap.status == AppBootstrapStatus.failed) {
      return path == '/bootstrap-error' ? null : '/bootstrap-error';
    }

    Session? session;
    try {
      session = Supabase.instance.client.auth.currentSession;
    } catch (_) {
      // Supabase may not be initialized yet (e.g., in widget tests).
      session = null;
    }
    final signedIn = session != null;

    // Prevent accessing authenticated areas with anon token (causes invalid JWT).
    if (!signedIn) {
      clearCachedUserProfile();
      if (path.startsWith('/servant/') && path != '/servant/login') {
        return '/servant/login';
      }
      if (path.startsWith('/student/') && path != '/student/login') {
        return '/student/login';
      }

      // Bootstrap is done: release the splash screen to the role selection.
      if (path == '/splash') return '/';
      return null;
    }

    final profile = await _resolveCurrentUserProfile();
    final role = profile?.role;
    final accountStatus = profile?.accountStatus;
    final isAdmin = role == 'admin';

    // Inactive accounts should not access any content.
    if (!isAdmin && accountStatus != null && accountStatus != 'active') {
      if (path != '/access-denied') return '/access-denied';
    } else if (path == '/access-denied') {
      if (role == 'student') return '/student/dashboard';
      if (role == 'servant' || role == 'admin') return '/servant/dashboard';
      return '/';
    }

    // Enforce role separation even when authenticated.
    if (path.startsWith('/student/') && path != '/student/login') {
      if (role == null) return '/';
      if (role != 'student') return '/servant/dashboard';
    }

    if (path.startsWith('/servant/') && path != '/servant/login') {
      if (role == null) return '/';
      final allowed = role == 'servant' || role == 'admin';
      if (!allowed) return '/student/dashboard';
    }

    // Bootstrap is done: release the splash screen (the profile above was
    // already fetched while it was mounted, so content appears immediately).
    if (path == '/splash') return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      name: 'role-selection',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/bootstrap-error',
      name: 'bootstrap-error',
      builder: (context, state) => BootstrapErrorScreen(
        message: AppBootstrap.instance.errorMessage ?? 'Bootstrap failed',
      ),
    ),
    GoRoute(
      path: '/access-denied',
      name: 'access-denied',
      builder: (context, state) => const AccessDeniedScreen(),
    ),
    GoRoute(
      path: '/student/login',
      name: 'student-login',
      builder: (context, state) => const StudentLoginScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          StudentShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/student/dashboard',
              name: 'student-dashboard',
              builder: (context, state) => const StudentDashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/student/attendance',
              name: 'student-attendance',
              builder: (context, state) => const StudentAttendanceScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/student/grades',
              name: 'student-grades',
              builder: (context, state) => const StudentGradesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/student/communication',
              name: 'student-communication',
              builder: (context, state) => StudentCommunicationScreen(
                initialTab: state.uri.queryParameters['tab'],
                initialCategory: state.uri.queryParameters['category'],
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/student/profile',
              name: 'student-profile',
              builder: (context, state) => const StudentProfileScreen(),
              routes: [
                GoRoute(
                  path: 'change-password',
                  name: 'student-change-password',
                  builder: (context, state) =>
                      const StudentChangePasswordScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/student/notifications',
      name: 'student-notifications',
      redirect: (context, state) => '/student/communication',
    ),
    GoRoute(
      path: '/servant/login',
      name: 'servant-login',
      builder: (context, state) => const ServantLoginScreen(),
    ),
    GoRoute(
      path: '/servant/messages',
      name: 'servant-messages',
      redirect: (context, state) => '/servant/communication',
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          ServantShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/servant/dashboard',
              name: 'servant-dashboard',
              builder: (context, state) => const ServantDashboardScreen(),
            ),
            GoRoute(
              path: '/servant/analytics',
              name: 'servant-analytics',
              builder: (context, state) => const ServantAnalyticsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/servant/attendance',
              name: 'servant-attendance',
              builder: (context, state) => const ServantAttendanceScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/servant/grades',
              name: 'servant-grades',
              builder: (context, state) => const ServantGradesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/servant/communication',
              name: 'servant-communication',
              builder: (context, state) => ServantCommunicationScreen(
                initialTab: state.uri.queryParameters['tab'],
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/servant/profile',
              name: 'servant-profile',
              builder: (context, state) => const ServantProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/:path(.*)',
      name: 'not-found',
      redirect: (context, state) => '/',
    ),
  ],
);

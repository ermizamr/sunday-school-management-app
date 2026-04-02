import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/student/presentation/student_screens.dart';
import '../../features/servant/presentation/analytics/servant_analytics_screen.dart';
import '../../features/servant/presentation/servant_screens.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

String? _cachedRoleUserId;
String? _cachedRole;
bool _cachedRoleLoaded = false;
Future<void>? _roleFetchInProgress;

void _clearRoleCache() {
  _cachedRoleUserId = null;
  _cachedRole = null;
  _cachedRoleLoaded = false;
  _roleFetchInProgress = null;
}

Future<String?> _resolveCurrentUserRole() async {
  String? userId;
  try {
    userId = Supabase.instance.client.auth.currentUser?.id;
  } catch (_) {
    return null;
  }

  if (userId == null) {
    _clearRoleCache();
    return null;
  }

  final resolvedUserId = userId;

  if (_cachedRoleUserId != resolvedUserId) {
    _clearRoleCache();
    _cachedRoleUserId = resolvedUserId;
  }

  if (_cachedRoleLoaded) return _cachedRole;

  final inProgress = _roleFetchInProgress;
  if (inProgress != null) {
    await inProgress;
    return _cachedRole;
  }

  final fetch = _roleFetchInProgress = () async {
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', resolvedUserId)
          .maybeSingle();

      _cachedRole = profile?['role']?.toString().trim().toLowerCase();
    } catch (_) {
      _cachedRole = null;
    } finally {
      _cachedRoleLoaded = true;
      _roleFetchInProgress = null;
    }
  }();

  await fetch;
  return _cachedRole;
}

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) async {
    final path = state.uri.path;
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
      if (path.startsWith('/servant/') && path != '/servant/login') {
        return '/servant/login';
      }
      if (path.startsWith('/student/') && path != '/student/login') {
        return '/student/login';
      }

      return null;
    }

    // Enforce role separation even when authenticated.
    if (path.startsWith('/student/') && path != '/student/login') {
      final role = await _resolveCurrentUserRole();
      if (role == null) return '/';
      if (role != 'student') return '/servant/dashboard';
    }

    if (path.startsWith('/servant/') && path != '/servant/login') {
      final role = await _resolveCurrentUserRole();
      if (role == null) return '/';
      final allowed = role == 'servant' || role == 'admin';
      if (!allowed) return '/student/dashboard';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      name: 'role-selection',
      builder: (context, state) => const RoleSelectionScreen(),
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

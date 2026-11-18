import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunday_school_app/l10n/app_localizations.dart';

import 'core/bootstrap/app_bootstrap.dart';
import 'core/refresh/app_refresh_controller.dart';
import 'core/refresh/app_refresh_scope.dart';
import 'core/refresh/global_refresh_indicator.dart';
import 'core/push/push_notifications_service.dart';
import 'core/routing/app_router.dart';
import 'core/supabase/supabase_client.dart';

/// Minimum time the splash screen stays visible so its entrance animation can
/// play even when bootstrap finishes quickly.
const _minSplashDuration = Duration(milliseconds: 800);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Render the splash screen immediately and bootstrap in the background, so
  // users never stare at a black screen while Supabase authenticates.
  AppBootstrap.instance.markInitializing();
  runApp(const ProviderScope(child: SundaySchoolApp()));

  Object? bootstrapError;
  await Future.wait<void>([
    _initializeApp().then<void>((error) {
      bootstrapError = error;
    }),
    Future<void>.delayed(_minSplashDuration),
  ]);

  final error = bootstrapError;
  if (error != null) {
    AppBootstrap.instance.markFailed(error);
  } else {
    AppBootstrap.instance.markReady();
  }
  appRouter.refresh();
}

/// Initializes Supabase and push notifications.
///
/// Returns the fatal bootstrap error (Supabase) instead of throwing so the
/// splash screen can keep its minimum duration before the error is surfaced.
/// Push notification failures are reported but not fatal.
Future<Object?> _initializeApp() async {
  try {
    await SupabaseClientManager.instance.init();
  } catch (e, st) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: e, stack: st, library: 'app bootstrap'),
    );
    return e;
  }

  try {
    await PushNotificationsService.instance.init();
  } catch (e, st) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: e, stack: st, library: 'push bootstrap'),
    );
  }
  return null;
}

class SundaySchoolApp extends StatefulWidget {
  const SundaySchoolApp({super.key});

  @override
  State<SundaySchoolApp> createState() => _SundaySchoolAppState();
}

class _SundaySchoolAppState extends State<SundaySchoolApp> {
  late final AppRefreshController _refreshController = AppRefreshController(
    defaultOnRefresh: () async {
      final client = SupabaseClientManager.instance.client;

      try {
        await client.auth.refreshSession();
      } catch (e) {
        final msg = e.toString().toLowerCase();
        final looksLikeInvalidJwt =
            msg.contains('invalid jwt') ||
            (msg.contains('jwt') && msg.contains('invalid'));
        if (looksLikeInvalidJwt) {
          try {
            await PushNotificationsService.instance.unregisterBeforeSignOut();
          } catch (_) {}
          try {
            await client.auth.signOut();
          } catch (_) {}
          try {
            clearCachedUserProfile();
            appRouter.refresh();
          } catch (_) {}
          return;
        }
      }

      try {
        final userId = client.auth.currentUser?.id;
        if (userId != null) {
          final profile = await client
              .from('profiles')
              .select('role, account_status')
              .eq('id', userId)
              .maybeSingle();

          final role = profile?['role']?.toString().trim().toLowerCase();
          final accountStatus = profile?['account_status']
              ?.toString()
              .trim()
              .toLowerCase();

          final shouldSignOut =
              role != 'admin' &&
              accountStatus != null &&
              accountStatus != 'active';

          if (shouldSignOut) {
            try {
              await PushNotificationsService.instance.unregisterBeforeSignOut();
            } catch (_) {}
            try {
              await client.auth.signOut();
            } catch (_) {}

            try {
              clearCachedUserProfile();
              appRouter.refresh();
            } catch (_) {}
            return;
          }
        }
      } catch (_) {}

      try {
        clearCachedUserProfile();
        appRouter.refresh();
      } catch (_) {}
    },
  );

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0EA5E9)),
      useMaterial3: true,
    );

    const locale = Locale('am');

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: theme,
      locale: locale,
      localeResolutionCallback: (deviceLocale, supportedLocales) => locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [locale],
      routerConfig: appRouter,
      builder: (context, child) {
        final routedChild = child ?? const SizedBox.shrink();
        return AppRefreshScope(
          controller: _refreshController,
          child: GlobalRefreshIndicator(child: routedChild),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sunday_school_app/l10n/app_localizations.dart';

import 'core/bootstrap/bootstrap_error_screen.dart';
import 'core/refresh/app_refresh_controller.dart';
import 'core/refresh/app_refresh_scope.dart';
import 'core/refresh/global_refresh_indicator.dart';
import 'core/push/push_notifications_service.dart';
import 'core/routing/app_router.dart';
import 'core/supabase/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? bootstrapError;
  try {
    await SupabaseClientManager.instance.init();
    try {
      await PushNotificationsService.instance.init();
    } catch (e, st) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: e, stack: st, library: 'push bootstrap'),
      );
    }
  } catch (e, st) {
    bootstrapError = e;
    FlutterError.reportError(
      FlutterErrorDetails(exception: e, stack: st, library: 'app bootstrap'),
    );
  }

  runApp(ProviderScope(child: SundaySchoolApp(bootstrapError: bootstrapError)));
}

class SundaySchoolApp extends StatefulWidget {
  const SundaySchoolApp({super.key, this.bootstrapError});

  final Object? bootstrapError;

  @override
  State<SundaySchoolApp> createState() => _SundaySchoolAppState();
}

class _SundaySchoolAppState extends State<SundaySchoolApp> {
  late final AppRefreshController _refreshController = AppRefreshController(
    defaultOnRefresh: () async {
      try {
        await SupabaseClientManager.instance.client.auth.refreshSession();
      } catch (e) {
        final msg = e.toString().toLowerCase();
        final looksLikeInvalidJwt =
            msg.contains('invalid jwt') ||
            (msg.contains('jwt') && msg.contains('invalid'));
        if (looksLikeInvalidJwt) {
          try {
            await SupabaseClientManager.instance.client.auth.signOut();
          } catch (_) {}
        }
      }
      try {
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

    if (widget.bootstrapError != null) {
      return MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: theme,
        locale: locale,
        localeResolutionCallback: (deviceLocale, supportedLocales) => locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const [locale],
        home: BootstrapErrorScreen(message: widget.bootstrapError.toString()),
      );
    }

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

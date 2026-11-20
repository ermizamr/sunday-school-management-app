import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sunday_school_app/l10n/app_localizations.dart';

import '../../../core/push/push_notifications_service.dart';
import '../../../core/refresh/app_refresh_configurator.dart';

class AccessDeniedScreen extends StatefulWidget {
  const AccessDeniedScreen({super.key});

  @override
  State<AccessDeniedScreen> createState() => _AccessDeniedScreenState();
}

class _AccessDeniedScreenState extends State<AccessDeniedScreen> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);

    try {
      await PushNotificationsService.instance.unregisterBeforeSignOut();
    } catch (_) {}

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}

    if (!mounted) return;
    setState(() => _signingOut = false);
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: AppRefreshConfigurator(
          onRefresh: null,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 120),
              const Icon(Icons.lock_rounded, size: 52),
              const SizedBox(height: 16),
              Text(
                l10n.studentGradesAccountInactiveTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.studentGradesAccountInactiveMessage,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    onPressed: _signingOut ? null : _signOut,
                    child: _signingOut
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.commonSignOut),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

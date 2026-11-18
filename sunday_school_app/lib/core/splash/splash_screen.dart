import 'package:flutter/material.dart';
import 'package:sunday_school_app/l10n/app_localizations.dart';

/// Full-screen splash shown while the app bootstraps.
///
/// It is the very first widget the router resolves, so users see the logo and
/// a gentle entrance animation instead of a black screen while Supabase
/// authenticates in the background.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _brandColor = Color(0xFF0EA5E9);
  static const _titleColor = Color(0xFF0F172A);

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  // Subtle continuous breathing so the screen feels alive during longer waits.
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
        ..repeat(reverse: true);

  late final Animation<double> _logoOpacity = _enter.drive(
    CurveTween(curve: const Interval(0, 0.55, curve: Curves.easeOut)),
  );

  late final Animation<double> _logoScale = _enter
      .drive(CurveTween(curve: const Interval(0, 0.45, curve: Curves.easeOutCubic)))
      .drive(Tween<double>(begin: 0.86, end: 1));

  late final Animation<double> _titleOpacity = _enter.drive(
    CurveTween(curve: const Interval(0.25, 0.75, curve: Curves.easeOut)),
  );

  late final Animation<Offset> _titleSlide = _enter
      .drive(CurveTween(curve: const Interval(0.25, 0.75, curve: Curves.easeOutCubic)))
      .drive(Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero));

  late final Animation<double> _spinnerOpacity = _enter.drive(
    CurveTween(curve: const Interval(0.5, 1, curve: Curves.easeOut)),
  );

  late final Animation<double> _pulseScale = _pulse.drive(
    Tween<double>(begin: 1, end: 1.02),
  );

  @override
  void initState() {
    super.initState();
    _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _logoOpacity,
              child: ScaleTransition(
                scale: _logoScale,
                child: ScaleTransition(
                  scale: _pulseScale,
                  child: Image.asset('assets/logo.png', width: 196, height: 196),
                ),
              ),
            ),
            const SizedBox(height: 28),
            SlideTransition(
              position: _titleSlide,
              child: FadeTransition(
                opacity: _titleOpacity,
                child: Text(
                  l10n.appTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _titleColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _spinnerOpacity,
              child: const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: _brandColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

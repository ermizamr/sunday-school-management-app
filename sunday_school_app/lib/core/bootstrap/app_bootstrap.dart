/// Lifecycle of the app bootstrap (Supabase + push notifications init).
///
/// The router reads this to decide whether to hold users on the splash
/// screen, release them into the app, or show the bootstrap error screen.
enum AppBootstrapStatus { initializing, ready, failed }

class AppBootstrap {
  AppBootstrap._();

  static final AppBootstrap instance = AppBootstrap._();

  /// Defaults to [AppBootstrapStatus.ready] so widgets pumped directly (for
  /// example in widget tests) render content without running [main].
  AppBootstrapStatus status = AppBootstrapStatus.ready;

  String? errorMessage;

  void markInitializing() {
    status = AppBootstrapStatus.initializing;
    errorMessage = null;
  }

  void markReady() {
    status = AppBootstrapStatus.ready;
    errorMessage = null;
  }

  void markFailed(Object error) {
    status = AppBootstrapStatus.failed;
    errorMessage = error.toString();
  }
}

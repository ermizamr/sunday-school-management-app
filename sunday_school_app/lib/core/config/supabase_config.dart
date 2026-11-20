/// Supabase connection settings for the mobile app.
///
/// The values below are the baked-in defaults. Override them at build time
/// without editing this file using `--dart-define`:
///
/// ```sh
/// flutter build apk --release \
///   --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
/// ```
///
/// Because these are compile-time constants, changing the target still
/// requires a rebuild — but never a code change.
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://eucvcyqrgdlkrhoekqtq.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV1Y3ZjeXFyZ2Rsa3Job2VrcXRxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQ5OTU2OTYsImV4cCI6MjExMDU3MTY5Nn0.10gLIzQRbiaa1qOqlQ5HFZgiNQ3Ae6FykPxOJCddERM',
  );
}

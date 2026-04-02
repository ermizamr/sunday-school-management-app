import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  String _identifierToEmail(String identifier) {
    final trimmed = identifier.trim();
    if (trimmed.contains('@')) return trimmed;

    // Academic IDs can contain '/' (e.g. 1234/26). Supabase Auth email validation
    // may reject that, so we map it to a deterministic local email.
    final local = trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    return '${local.isEmpty ? 'student' : local}@school.local';
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: _identifierToEmail(email),
      password: password,
    );
  }

  Future<String?> fetchCurrentUserRole() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final profile = await _client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    return profile?['role']?.toString();
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }
}

AuthRepository createAuthRepository() {
  final client = SupabaseClientManager.instance.client;
  return AuthRepository(client);
}

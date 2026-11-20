import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart';

String presentErrorMessage(
  AppLocalizations l10n,
  Object error, {
  String? fallback,
}) {
  final msgLower = _errorMessageLower(error);

  if (_isMissingGradeAssignment(msgLower)) {
    return l10n.errorMissingGradeAssignment;
  }

  if (_isMissingAcademicYear(msgLower)) {
    return l10n.errorMissingActiveAcademicYear;
  }

  if (_isAuthError(error, msgLower)) {
    return l10n.errorAuthRequired;
  }

  if (_isNetworkError(error, msgLower)) {
    return l10n.errorNetwork;
  }

  return fallback ?? l10n.errorSomethingWentWrong;
}

String _errorMessageLower(Object error) {
  final msg = switch (error) {
    StateError e => e.message,
    AuthException e => e.message,
    PostgrestException e =>
      '${e.code ?? ''} ${e.message} ${e.details ?? ''} ${e.hint ?? ''}',
    _ => error.toString(),
  };

  return msg.toLowerCase();
}

bool _isNetworkError(Object error, String msgLower) {
  if (error is TimeoutException) return true;

  final typeLower = error.runtimeType.toString().toLowerCase();
  if (typeLower.contains('socketexception') ||
      typeLower.contains('handshakeexception') ||
      typeLower.contains('clientexception')) {
    return true;
  }

  return msgLower.contains('socketexception') ||
      msgLower.contains('failed host lookup') ||
      msgLower.contains('no address associated with hostname') ||
      msgLower.contains('connection refused') ||
      msgLower.contains('connection reset') ||
      msgLower.contains('connection timed out') ||
      msgLower.contains('timed out') ||
      msgLower.contains('failed to fetch') ||
      msgLower.contains('xmlhttprequest') ||
      msgLower.contains('clientexception');
}

bool _isAuthError(Object error, String msgLower) {
  if (error is AuthException) return true;
  if (error is PostgrestException) {
    final codeLower = (error.code ?? '').toLowerCase();
    if (codeLower == 'pgrst301') return true;
  }

  return msgLower.contains('not signed in') ||
      msgLower.contains('not_signed_in') ||
      msgLower.contains('jwt') ||
      msgLower.contains('unauthorized') ||
      msgLower.contains('forbidden') ||
      msgLower.contains('permission denied') ||
      msgLower.contains('invalid token') ||
      msgLower.contains('authentication required');
}

bool _isMissingAcademicYear(String msgLower) {
  return msgLower.contains('missing academic year') ||
      msgLower.contains('missing_academic_year') ||
      msgLower.contains('no active academic year') ||
      msgLower.contains('missing active academic year') ||
      msgLower.contains('academic_year') && msgLower.contains('missing');
}

bool _isMissingGradeAssignment(String msgLower) {
  return msgLower.contains('missing grade assignment') ||
      msgLower.contains('missing_grade_assignment') ||
      msgLower.contains('grade assignment') && msgLower.contains('missing');
}

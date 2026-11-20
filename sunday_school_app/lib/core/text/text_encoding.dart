import 'dart:convert';

bool _containsEthiopic(String value) {
  for (final r in value.runes) {
    if (r >= 0x1200 && r <= 0x137F) return true;
  }
  return false;
}

bool _looksLikeMojibake(String value) {
  // Common mojibake markers when UTF-8 bytes were mis-decoded as Latin-1
  // (often appearing as sequences like "Ã…", "Â…", "Ãƒ", etc.).
  return value.contains('Ã') ||
      value.contains('Â') ||
      value.contains('â') ||
      value.contains('á') ||
      value.contains('ê') ||
      value.contains('ƒ') ||
      value.contains('Æ') ||
      value.contains('�');
}

/// Attempts to repair strings that look like UTF-8 text mis-decoded as Latin-1.
///
/// This is intentionally conservative:
/// - If the string already contains Ethiopic characters, it is returned as-is.
/// - A repair is only accepted if it results in Ethiopic characters.
String maybeFixMojibake(String value) {
  if (value.isEmpty) return value;
  if (_containsEthiopic(value)) return value;
  if (!_looksLikeMojibake(value)) return value;

  String tryDecode(String input) {
    try {
      return utf8.decode(latin1.encode(input), allowMalformed: true);
    } catch (_) {
      return input;
    }
  }

  final once = tryDecode(value);
  if (_containsEthiopic(once)) return once;

  final twice = tryDecode(once);
  if (_containsEthiopic(twice)) return twice;

  return value;
}

String? maybeFixMojibakeNullable(String? value) {
  if (value == null) return null;
  return maybeFixMojibake(value);
}

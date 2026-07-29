/// Derives avatar initials from a display name.
///
/// The presentation models on the `shakira` branch stored `initials` as their
/// own field alongside a separate name field, which allows the two to disagree.
/// Deriving initials keeps one source of truth for a person's identity.
///
/// Uses runes rather than `String[0]` so a name beginning with a multi-byte
/// character does not produce half a code point.
String initialsFrom(String displayName) {
  final parts = displayName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) return '?';

  String firstRune(String value) => String.fromCharCode(value.runes.first);

  if (parts.length == 1) return firstRune(parts.first).toUpperCase();
  return (firstRune(parts.first) + firstRune(parts.last)).toUpperCase();
}

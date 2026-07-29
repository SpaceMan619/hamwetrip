/// Tolerant field readers shared by every domain model.
///
/// The same map has to be parsed from three very different sources:
///
///  * **Firestore server data** — timestamps arrive as `Timestamp` objects.
///  * **Firestore pending local writes** — a `FieldValue.serverTimestamp()`
///    reads back as `null` until the server acknowledges the write. Every
///    offline create passes through this state, so a model that assumes a
///    non-null `createdAt` will crash the moment the user loses signal.
///  * **Mocks and tests** — plain `DateTime`, `int`, or ISO `String`.
///
/// Parsing lives here so it is written once and tested once, and so the domain
/// layer never has to import `cloud_firestore`.
library;

/// Reads a timestamp in any of the shapes described above.
///
/// Returns `null` for a missing value or an unacknowledged server timestamp —
/// callers must treat null as "pending", not as an error.
/// Always returns UTC; conversion to local time is a UI concern.
DateTime? parseDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }
  if (value is String) return DateTime.tryParse(value)?.toUtc();

  // Firestore's `Timestamp`. Duck-typed rather than imported so this file —
  // and everything downstream of it — stays free of Firebase dependencies.
  try {
    final dynamic candidate = value;
    final Object? converted = candidate.toDate();
    if (converted is DateTime) return converted.toUtc();
  } on NoSuchMethodError {
    // Not a Timestamp. Fall through.
  }
  return null;
}

/// Serializes a [DateTime] for storage, normalized to UTC.
///
/// Null is preserved so a caller can distinguish "not set" from "epoch".
DateTime? writeDateTime(DateTime? value) => value?.toUtc();

/// Reads a required string, falling back to [fallback] when absent or of the
/// wrong type. Firestore fields can be missing entirely on older documents.
String parseString(Object? value, {String fallback = ''}) {
  if (value is String) return value;
  return fallback;
}

/// Reads an optional string. Empty strings collapse to null so the UI does not
/// have to check both.
String? parseOptionalString(Object? value) {
  if (value is String && value.isNotEmpty) return value;
  return null;
}

/// Reads an integer, tolerating values that arrive as `num` or numeric string.
///
/// Money is stored as integer minor units, so a value silently arriving as a
/// double would be a correctness bug — it is truncated here and should be
/// caught by the round-trip tests rather than reaching a balance calculation.
int parseInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Reads an optional integer, preserving the difference between "absent" and
/// "zero" — which matters for a denormalized balance that has never been
/// computed versus one that has settled to zero.
int? parseOptionalInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Reads a boolean, defaulting to [fallback] when the field is missing.
bool parseBool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  return fallback;
}

/// Reads a list of strings, dropping any non-string entries rather than
/// throwing — one malformed entry should not make a trip unreadable.
List<String> parseStringList(Object? value) {
  if (value is Iterable) {
    return value.whereType<String>().toList(growable: false);
  }
  return const [];
}

/// Reads an enum stored as a stable lowercase wire string.
///
/// [wireOf] supplies the stored representation, which is deliberately *not*
/// derived from the Dart constant name: the delivery guide specifies snake_case
/// values such as `vote_cast` and `claimed_paid`, and decoupling the two means
/// a Dart constant can be renamed without rewriting stored documents.
///
/// Unrecognized values resolve to [fallback] instead of throwing. This is
/// deliberate — a client running an older build must not crash when the backend
/// starts writing an activity type or status it has never heard of.
T parseWireEnum<T>(
  Object? value,
  List<T> values,
  String Function(T) wireOf,
  T fallback,
) {
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    for (final candidate in values) {
      if (wireOf(candidate).toLowerCase() == normalized) return candidate;
    }
  }
  return fallback;
}

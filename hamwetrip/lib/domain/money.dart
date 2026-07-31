import 'package:flutter/foundation.dart';

/// Money as integer minor units, and the split arithmetic the ledger needs.
///
/// Never floating point. A `double` cannot represent most decimal amounts
/// exactly, so a ledger built on one drifts by a unit or two and then cannot
/// be reconciled — which for a settlement app is the whole product.
///
/// ## RWF has no minor unit
///
/// A stored `5000` means RWF 5,000, not RWF 50.00. [minorUnitDigitsFor]
/// returns 0 for RWF, so its minor unit *is* its major unit. Currencies with
/// cents are supported so the type is not wrong elsewhere, but the MVP is
/// single-currency.
///
/// ## Boundary with Firestore
///
/// Documents store a plain `int` (`Expense.amountMinor`, `Payment.amountMinor`,
/// `TripMember.balanceMinor`) plus the currency on the trip. [Money] is an
/// in-memory computation type: build one with [Money.new] when reading, and
/// write [minorUnits] back out. It is deliberately not serialized itself —
/// storing the currency on every amount would give the trip two sources of
/// truth about its own currency.
@immutable
class Money implements Comparable<Money> {
  /// Builds an amount from minor units — the representation everything is
  /// stored in.
  const Money(this.minorUnits, this.currency);

  const Money.zero([this.currency = 'RWF']) : minorUnits = 0;

  /// Amount in minor units. For RWF this is whole francs.
  final int minorUnits;

  /// ISO 4217 code, e.g. `RWF`.
  final String currency;

  /// How many decimal places [currency] has. RWF has none.
  static int minorUnitDigitsFor(String currency) {
    return switch (currency.toUpperCase()) {
      // Zero-decimal currencies. RWF is the one the MVP ships with; the
      // others are here so a future trip in one of them is not silently
      // multiplied by a hundred.
      'RWF' || 'UGX' || 'TZS' || 'JPY' || 'KRW' || 'VND' || 'XAF' || 'XOF' => 0,
      _ => 2,
    };
  }

  /// Minor units per major unit: 1 for RWF, 100 for USD.
  static int factorFor(String currency) {
    return switch (minorUnitDigitsFor(currency)) {
      0 => 1,
      2 => 100,
      final digits => _pow10(digits),
    };
  }

  static int _pow10(int exponent) {
    var value = 1;
    for (var i = 0; i < exponent; i++) {
      value *= 10;
    }
    return value;
  }

  /// Parses a user-entered amount such as `"5000"`, `"5,000"` or `"50.25"`.
  ///
  /// Deliberately string-based rather than taking a `num`: multiplying a
  /// double by 100 is the floating-point path this class exists to avoid.
  /// `1.15 * 100` is `114.99999999999999`, and rounding only hides that.
  ///
  /// Throws [FormatException] on anything unparseable, and on more decimal
  /// places than [currency] has — `"50.25"` in RWF is rejected rather than
  /// quietly truncated to 50, because silently dropping someone's money is
  /// worse than making them retype it.
  factory Money.parse(String input, String currency) {
    final cleaned = input.trim().replaceAll(',', '').replaceAll(' ', '');
    if (!RegExp(r'^-?\d+(\.\d+)?$').hasMatch(cleaned)) {
      throw FormatException('Not a valid amount', input);
    }

    final digits = minorUnitDigitsFor(currency);
    final negative = cleaned.startsWith('-');
    final unsigned = negative ? cleaned.substring(1) : cleaned;
    final parts = unsigned.split('.');
    final whole = int.parse(parts[0]);
    final fraction = parts.length > 1 ? parts[1] : '';

    if (fraction.length > digits) {
      throw FormatException(
        digits == 0
            ? '$currency has no decimal places'
            : '$currency allows at most $digits decimal places',
        input,
      );
    }

    final scaled =
        whole * factorFor(currency) +
        (digits == 0 ? 0 : int.parse(fraction.padRight(digits, '0')));
    return Money(negative ? -scaled : scaled, currency);
  }

  bool get isZero => minorUnits == 0;
  bool get isNegative => minorUnits < 0;

  Money get abs => Money(minorUnits.abs(), currency);

  /// Lossy conversion for display or debugging only.
  ///
  /// Never feed this back into a calculation or a stored amount — that is
  /// exactly how a ledger starts drifting.
  double get asMajorUnits => minorUnits / factorFor(currency);

  /// Renders for the UI, e.g. `RWF 5,000` or `USD 50.25`.
  String format() {
    final digits = minorUnitDigitsFor(currency);
    final factor = factorFor(currency);
    final magnitude = minorUnits.abs();

    final buffer = StringBuffer();
    if (isNegative) buffer.write('-');
    buffer.write(currency.toUpperCase());
    buffer.write(' ');
    buffer.write(_group(magnitude ~/ factor));
    if (digits > 0) {
      buffer.write('.');
      buffer.write((magnitude % factor).toString().padLeft(digits, '0'));
    }
    return buffer.toString();
  }

  /// Thousands separators, hand-rolled rather than via `intl` so the output
  /// does not change with the device locale. An amount that renders
  /// differently on two phones is a support problem.
  static String _group(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits + other.minorUnits, currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits - other.minorUnits, currency);
  }

  Money operator -() => Money(-minorUnits, currency);

  bool operator <(Money other) => compareTo(other) < 0;
  bool operator <=(Money other) => compareTo(other) <= 0;
  bool operator >(Money other) => compareTo(other) > 0;
  bool operator >=(Money other) => compareTo(other) >= 0;

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  void _assertSameCurrency(Money other) {
    if (other.currency.toUpperCase() != currency.toUpperCase()) {
      throw ArgumentError('Currency mismatch: $currency vs ${other.currency}');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currency.toUpperCase() == currency.toUpperCase();

  @override
  int get hashCode => Object.hash(minorUnits, currency.toUpperCase());

  @override
  String toString() => '$minorUnits $currency';
}

/// Splits [total] as evenly as integer units allow.
///
/// The remainder goes one unit at a time to the uids that sort first, so every
/// device computing the same split reaches byte-identical amounts. RWF 5,000
/// across three people is `[1667, 1667, 1666]`, never `1666.67` each.
///
/// Throws [ArgumentError] when [uids] is empty, contains duplicates, or when
/// [total] is negative — an expense is money someone spent, and the negative
/// case has no defined remainder direction. (Truncating division and modulo
/// disagree on sign in Dart: `-100 ~/ 3` is `-33` while `-100 % 3` is `2`, so
/// naively reusing the positive branch loses units.)
///
/// The returned amounts always sum exactly to [total].
Map<String, Money> splitEqually(Money total, List<String> uids) {
  if (uids.isEmpty) {
    throw ArgumentError.value(uids, 'uids', 'Cannot split among nobody');
  }
  if (uids.toSet().length != uids.length) {
    // Left unchecked, a repeated uid overwrites its own entry and the parts
    // quietly stop summing to the total.
    throw ArgumentError.value(uids, 'uids', 'Contains duplicate participants');
  }
  if (total.isNegative) {
    throw ArgumentError.value(
      total.minorUnits,
      'total',
      'Cannot split a negative amount',
    );
  }

  final sorted = [...uids]..sort();
  final count = sorted.length;
  final base = total.minorUnits ~/ count;
  final remainder = total.minorUnits % count;

  return <String, Money>{
    for (var i = 0; i < count; i++)
      sorted[i]: Money(base + (i < remainder ? 1 : 0), total.currency),
  };
}

/// Validates a hand-entered split and returns it unchanged.
///
/// Checks both that every share is in [total]'s currency and that the shares
/// sum to exactly [total]. Summing alone is not enough: without the currency
/// check, RWF 5,000 would validate against USD 2,500 + EUR 2,500.
///
/// Throws [ArgumentError] on either failure.
Map<String, Money> splitCustom(Money total, Map<String, Money> shares) {
  if (shares.isEmpty) {
    throw ArgumentError.value(shares, 'shares', 'Cannot split among nobody');
  }

  for (final entry in shares.entries) {
    if (entry.value.currency.toUpperCase() != total.currency.toUpperCase()) {
      throw ArgumentError(
        'Share for ${entry.key} is in ${entry.value.currency}, '
        'but the total is in ${total.currency}',
      );
    }
    if (entry.value.isNegative) {
      throw ArgumentError('Share for ${entry.key} is negative');
    }
  }

  final sum = shares.values.fold<int>(0, (acc, m) => acc + m.minorUnits);
  if (sum != total.minorUnits) {
    throw ArgumentError(
      'Shares sum to $sum but the total is ${total.minorUnits}',
    );
  }
  return shares;
}

/// Integer minor-unit money handling.
/// RWF has no minor unit — treat it as whole-unit only.
class Money {
  final int minorUnits; // e.g. cents. For RWF, this IS the whole unit.
  final String currency;

  const Money(this.minorUnits, this.currency);

  static int _factorFor(String currency) {
    // RWF has no minor unit (no cents).
    if (currency == 'RWF') return 1;
    return 100; // default: 2 decimal places (USD, EUR, etc.)
  }

  factory Money.fromMajor(num majorAmount, String currency) {
    final factor = _factorFor(currency);
    return Money((majorAmount * factor).round(), currency);
  }

  double get asMajorUnits => minorUnits / _factorFor(currency);

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits + other.minorUnits, currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits - other.minorUnits, currency);
  }

  void _assertSameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError(
          'Currency mismatch: $currency vs ${other.currency}');
    }
  }

  @override
  String toString() => '$minorUnits $currency';

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);
}

/// Splits [total] evenly among [uids], distributing the remainder
/// deterministically to the first N uids when sorted alphabetically.
/// This guarantees the same split result on every device, every time.
Map<String, Money> splitEqually(Money total, List<String> uids) {
  if (uids.isEmpty) {
    throw ArgumentError('Cannot split among zero participants');
  }

  final sortedUids = [...uids]..sort();
  final n = sortedUids.length;
  final base = total.minorUnits ~/ n;
  final remainder = total.minorUnits % n;

  final result = <String, Money>{};
  for (var i = 0; i < n; i++) {
    // First `remainder` uids (in sorted order) get one extra minor unit.
    final amount = base + (i < remainder ? 1 : 0);
    result[sortedUids[i]] = Money(amount, total.currency);
  }
  return result;
}

/// Splits [total] by custom weights (e.g. {uid: shareAmount}),
/// validating that the shares sum to the total.
Map<String, Money> splitCustom(
    Money total, Map<String, Money> customShares) {
  final sum = customShares.values
      .fold<int>(0, (acc, m) => acc + m.minorUnits);
  if (sum != total.minorUnits) {
    throw ArgumentError(
        'Custom split shares ($sum) do not sum to total (${total.minorUnits})');
  }
  return customShares;
}
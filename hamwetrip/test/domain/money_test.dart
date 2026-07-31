import 'package:flutter_test/flutter_test.dart';
import 'package:hamwetrip/domain/money.dart';

void main() {
  group('currency metadata', () {
    test('RWF has no minor unit', () {
      expect(Money.minorUnitDigitsFor('RWF'), 0);
      expect(Money.factorFor('RWF'), 1);
      // A stored 5000 is RWF 5,000, not RWF 50.00.
      expect(const Money(5000, 'RWF').asMajorUnits, 5000);
    });

    test('decimal currencies use cents', () {
      expect(Money.minorUnitDigitsFor('USD'), 2);
      expect(Money.factorFor('USD'), 100);
    });

    test('currency codes are case insensitive', () {
      expect(Money.minorUnitDigitsFor('rwf'), 0);
      expect(const Money(100, 'RWF'), const Money(100, 'rwf'));
    });
  });

  group('parse', () {
    test('reads plain and grouped input', () {
      expect(Money.parse('5000', 'RWF').minorUnits, 5000);
      expect(Money.parse('5,000', 'RWF').minorUnits, 5000);
      expect(Money.parse(' 5000 ', 'RWF').minorUnits, 5000);
    });

    test('reads decimals exactly, with no floating point in the path', () {
      // 1.15 * 100 in binary floating point is 114.99999999999999. Parsing
      // from the string avoids the question entirely.
      expect(Money.parse('1.15', 'USD').minorUnits, 115);
      expect(Money.parse('0.07', 'USD').minorUnits, 7);
      expect(Money.parse('50.25', 'USD').minorUnits, 5025);
      expect(Money.parse('50.2', 'USD').minorUnits, 5020);
    });

    test('rejects decimals for a currency that has none', () {
      // Truncating to 50 would silently discard money.
      expect(() => Money.parse('50.25', 'RWF'), throwsFormatException);
    });

    test('rejects more precision than the currency allows', () {
      expect(() => Money.parse('1.234', 'USD'), throwsFormatException);
    });

    test('rejects junk', () {
      for (final bad in ['', 'abc', '1.2.3', '5 000x', '--5']) {
        expect(
          () => Money.parse(bad, 'RWF'),
          throwsFormatException,
          reason: 'should reject "$bad"',
        );
      }
    });

    test('handles negatives', () {
      expect(Money.parse('-5000', 'RWF').minorUnits, -5000);
    });
  });

  group('format', () {
    test('groups thousands', () {
      expect(const Money(5000, 'RWF').format(), 'RWF 5,000');
      expect(const Money(1234567, 'RWF').format(), 'RWF 1,234,567');
      expect(const Money(100, 'RWF').format(), 'RWF 100');
      expect(const Money(0, 'RWF').format(), 'RWF 0');
    });

    test('shows decimals only where the currency has them', () {
      expect(const Money(5025, 'USD').format(), 'USD 50.25');
      expect(const Money(5, 'USD').format(), 'USD 0.05');
      expect(const Money(5000, 'RWF').format(), 'RWF 5,000');
    });

    test('signs negatives', () {
      expect(const Money(-5000, 'RWF').format(), '-RWF 5,000');
    });

    test('round trips through parse', () {
      for (final amount in [0, 1, 999, 1000, 5000, 1234567]) {
        final money = Money(amount, 'RWF');
        expect(
          Money.parse(money.format().replaceAll('RWF ', ''), 'RWF'),
          money,
        );
      }
    });
  });

  group('arithmetic', () {
    test('adds and subtracts within one currency', () {
      expect(
        const Money(300, 'RWF') + const Money(200, 'RWF'),
        const Money(500, 'RWF'),
      );
      expect(
        const Money(300, 'RWF') - const Money(200, 'RWF'),
        const Money(100, 'RWF'),
      );
      expect(-const Money(300, 'RWF'), const Money(-300, 'RWF'));
    });

    test('refuses to mix currencies', () {
      expect(
        () => const Money(300, 'RWF') + const Money(200, 'USD'),
        throwsArgumentError,
      );
      expect(
        () => const Money(300, 'RWF').compareTo(const Money(1, 'USD')),
        throwsArgumentError,
      );
    });

    test('compares', () {
      expect(const Money(300, 'RWF') > const Money(200, 'RWF'), isTrue);
      expect(const Money(200, 'RWF') <= const Money(200, 'RWF'), isTrue);
    });
  });

  group('splitEqually', () {
    /// Every split must account for every unit — this is the invariant the
    /// whole ledger rests on.
    void expectSumsToTotal(int totalMinor, List<String> uids) {
      final total = Money(totalMinor, 'RWF');
      final split = splitEqually(total, uids);
      final sum = split.values.fold<int>(0, (a, m) => a + m.minorUnits);
      expect(
        sum,
        totalMinor,
        reason: 'split of $totalMinor among ${uids.length} lost units',
      );
      expect(split.length, uids.length);
    }

    test('divides evenly when it can', () {
      final split = splitEqually(const Money(300, 'RWF'), ['b', 'a', 'c']);
      expect(split['a']!.minorUnits, 100);
      expect(split['b']!.minorUnits, 100);
      expect(split['c']!.minorUnits, 100);
    });

    test('gives the remainder to the uids that sort first', () {
      // RWF 5,000 across three is the guide's worked example.
      final split = splitEqually(const Money(5000, 'RWF'), [
        'carol',
        'alice',
        'bob',
      ]);
      expect(split['alice']!.minorUnits, 1667);
      expect(split['bob']!.minorUnits, 1667);
      expect(split['carol']!.minorUnits, 1666);
    });

    test('is order independent, so every device agrees', () {
      final a = splitEqually(const Money(101, 'RWF'), ['z', 'y', 'x']);
      final b = splitEqually(const Money(101, 'RWF'), ['x', 'y', 'z']);
      expect(a, b);
    });

    test('always sums back to the total', () {
      for (final total in [0, 1, 2, 99, 100, 101, 5000, 999999]) {
        for (final count in [1, 2, 3, 4, 7, 13]) {
          expectSumsToTotal(
            total,
            List.generate(count, (i) => 'u${i.toString().padLeft(2, '0')}'),
          );
        }
      }
    });

    test('rejects an empty participant list', () {
      expect(
        () => splitEqually(const Money(100, 'RWF'), []),
        throwsArgumentError,
      );
    });

    test('rejects duplicate participants', () {
      // Left unchecked, the repeated uid overwrites its own entry and the
      // parts stop summing to the total.
      expect(
        () => splitEqually(const Money(300, 'RWF'), ['a', 'a', 'b']),
        throwsArgumentError,
      );
    });

    test('rejects a negative total', () {
      // Dart's ~/ truncates toward zero while % stays non-negative, so the
      // naive formula loses units on negatives: -100 across 3 would produce
      // [-32, -32, -33], summing to -97.
      expect(
        () => splitEqually(const Money(-100, 'RWF'), ['a', 'b', 'c']),
        throwsArgumentError,
      );
    });

    test('preserves the currency', () {
      final split = splitEqually(const Money(300, 'USD'), ['a', 'b', 'c']);
      expect(split['a']!.currency, 'USD');
    });
  });

  group('splitCustom', () {
    test('accepts shares that sum exactly', () {
      final shares = {
        'a': const Money(3000, 'RWF'),
        'b': const Money(2000, 'RWF'),
      };
      expect(splitCustom(const Money(5000, 'RWF'), shares), shares);
    });

    test('rejects shares that do not sum to the total', () {
      expect(
        () => splitCustom(const Money(5000, 'RWF'), {
          'a': const Money(3000, 'RWF'),
          'b': const Money(1000, 'RWF'),
        }),
        throwsArgumentError,
      );
    });

    test('rejects shares in another currency', () {
      // Checking only the sum would let RWF 5,000 validate against
      // USD 2,500 + EUR 2,500.
      expect(
        () => splitCustom(const Money(5000, 'RWF'), {
          'a': const Money(2500, 'USD'),
          'b': const Money(2500, 'EUR'),
        }),
        throwsArgumentError,
      );
    });

    test('rejects a negative share', () {
      expect(
        () => splitCustom(const Money(5000, 'RWF'), {
          'a': const Money(6000, 'RWF'),
          'b': const Money(-1000, 'RWF'),
        }),
        throwsArgumentError,
      );
    });

    test('rejects an empty split', () {
      expect(
        () => splitCustom(const Money(5000, 'RWF'), {}),
        throwsArgumentError,
      );
    });
  });
}

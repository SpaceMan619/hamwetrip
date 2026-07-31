import 'package:flutter_test/flutter_test.dart';
import 'package:your_app_name/utils/money.dart'; // ← fix this import path

void main() {
  group('Money', () {
    test('RWF has no minor unit', () {
      final m = Money.fromMajor(5000, 'RWF');
      expect(m.minorUnits, 5000);
    });

    test('USD uses cents', () {
      final m = Money.fromMajor(50.25, 'USD');
      expect(m.minorUnits, 5025);
    });
  });

  group('splitEqually', () {
    test('splits evenly with no remainder', () {
      final total = Money(300, 'RWF');
      final result = splitEqually(total, ['b', 'a', 'c']);
      expect(result['a']!.minorUnits, 100);
      expect(result['b']!.minorUnits, 100);
      expect(result['c']!.minorUnits, 100);
    });

    test('remainder goes to sorted-first uids deterministically', () {
      final total = Money(100, 'RWF');
      final result = splitEqually(total, ['charlie', 'alice', 'bob']);
      // 100 / 3 = 33 remainder 1 -> alice (sorted first) gets the extra
      expect(result['alice']!.minorUnits, 34);
      expect(result['bob']!.minorUnits, 33);
      expect(result['charlie']!.minorUnits, 33);
    });

    test('same input always produces same output', () {
      final total = Money(101, 'RWF');
      final r1 = splitEqually(total, ['z', 'y', 'x']);
      final r2 = splitEqually(total, ['x', 'y', 'z']);
      expect(r1, r2);
    });
  });
}
import 'package:intl/intl.dart';

final NumberFormat _rwfFormatter = NumberFormat('#,##0', 'en_US');

String formatRwf(num amount) => 'RWF ${_rwfFormatter.format(amount.round())}';

/// Uses the compact K form only for exact thousands; irregular values retain
/// their full comma-separated amount so nobody loses precision.
String formatRwfCompact(num amount) {
  final rounded = amount.round();
  if (rounded >= 1000 && rounded % 1000 == 0) {
    return 'RWF ${rounded ~/ 1000}K';
  }
  return formatRwf(rounded);
}

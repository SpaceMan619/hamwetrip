import 'package:intl/intl.dart';

final NumberFormat _rwfFormatter = NumberFormat('#,##0', 'en_US');

String formatRwf(num amount) => 'RWF ${_rwfFormatter.format(amount.round())}';

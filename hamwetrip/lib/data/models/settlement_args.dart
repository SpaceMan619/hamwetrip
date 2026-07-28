import 'package:flutter/foundation.dart';
import 'expense.dart';

@immutable
class SettlementArgs {
  final Balance balance;
  final String maskedPhone;
  final String referenceId;

  const SettlementArgs({
    required this.balance,
    required this.maskedPhone,
    required this.referenceId,
  });
}

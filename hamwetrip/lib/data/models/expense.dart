import 'package:flutter/foundation.dart';

@immutable
class Expense {
  final String id;
  final String description;
  final double amount;
  final String paidByInitials;
  final String paidByName;
  final String categoryEmoji;
  final String category;
  final List<String> splitAmongInitials;
  final DateTime date;

  const Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.paidByInitials,
    required this.paidByName,
    required this.categoryEmoji,
    required this.category,
    required this.splitAmongInitials,
    required this.date,
  });

  double get splitAmount =>
      splitAmongInitials.isNotEmpty ? amount / splitAmongInitials.length : 0;
}

@immutable
class Balance {
  final String fromInitials;
  final String fromName;
  final String toInitials;
  final String toName;
  final double amount;

  const Balance({
    required this.fromInitials,
    required this.fromName,
    required this.toInitials,
    required this.toName,
    required this.amount,
  });
}

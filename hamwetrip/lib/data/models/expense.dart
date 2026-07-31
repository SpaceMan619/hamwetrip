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

  Map<String, Object?> toMap() => {
    'description': description,
    'amount': amount,
    'paidByInitials': paidByInitials,
    'paidByName': paidByName,
    'categoryEmoji': categoryEmoji,
    'category': category,
    'splitAmongInitials': splitAmongInitials,
    'date': date.toIso8601String(),
  };

  factory Expense.fromMap(String id, Map<String, Object?> map) => Expense(
    id: id,
    description: map['description'] as String? ?? '',
    amount: (map['amount'] as num?)?.toDouble() ?? 0,
    paidByInitials: map['paidByInitials'] as String? ?? '',
    paidByName: map['paidByName'] as String? ?? '',
    categoryEmoji: map['categoryEmoji'] as String? ?? '',
    category: map['category'] as String? ?? '',
    splitAmongInitials: (map['splitAmongInitials'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList(),
    date: map['date'] != null
        ? DateTime.parse(map['date'] as String)
        : DateTime.now(),
  );
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

import '../../../../../data/models/expense.dart';

final List<Expense> mockExpenses = [
  Expense(
    id: 'exp_1',
    description: 'Private van rental - Day 1',
    amount: 85000, // RWF
    paidByInitials: 'RM',
    paidByName: 'Rajveer Malik',
    categoryEmoji: '🚐',
    category: 'Transport',
    splitAmongInitials: ['RM', 'SK', 'KZ', 'AJ'],
    date: DateTime(2026, 10, 12),
  ),
  Expense(
    id: 'exp_2',
    description: 'Lunch at lodge',
    amount: 45000,
    paidByInitials: 'KZ',
    paidByName: 'Kamanzi',
    categoryEmoji: '🍽️',
    category: 'Food',
    splitAmongInitials: ['RM', 'SK', 'KZ', 'AJ'],
    date: DateTime(2026, 10, 12),
  ),
  Expense(
    id: 'exp_3',
    description: 'Nyungwe Park Entry Fees',
    amount: 120000,
    paidByInitials: 'RM',
    paidByName: 'Rajveer Malik',
    categoryEmoji: '🎫',
    category: 'Activity',
    splitAmongInitials: ['RM', 'SK', 'KZ', 'AJ'],
    date: DateTime(2026, 10, 13),
  ),
  Expense(
    id: 'exp_4',
    description: 'Dinner in town',
    amount: 36000,
    paidByInitials: 'AJ',
    paidByName: 'Aime',
    categoryEmoji: '🍽️',
    category: 'Food',
    splitAmongInitials: ['RM', 'SK', 'KZ', 'AJ'],
    date: DateTime(2026, 10, 13),
  ),
  Expense(
    id: 'exp_5',
    description: 'Guide tips',
    amount: 20000,
    paidByInitials: 'SK',
    paidByName: 'Shakira',
    categoryEmoji: '💰',
    category: 'Tips',
    splitAmongInitials: ['RM', 'SK', 'KZ', 'AJ'],
    date: DateTime(2026, 10, 14),
  ),
];

/// Pre-calculated balances showing who owes whom.
final List<Balance> mockBalances = [
  Balance(
    fromInitials: 'SK',
    fromName: 'Shakira',
    toInitials: 'RM',
    toName: 'Rajveer Malik',
    amount: 20000, // SK paid 20k tips, others owe her 5k each. RM owes 5k.
  ),
  Balance(
    fromInitials: 'KZ',
    fromName: 'Kamanzi',
    toInitials: 'RM',
    toName: 'Rajveer Malik',
    amount: 40000, // RM paid 205k total, KZ paid 45k. KZ owes RM net.
  ),
  Balance(
    fromInitials: 'AJ',
    fromName: 'Aime',
    toInitials: 'RM',
    toName: 'Rajveer Malik',
    amount: 46000, // AJ paid 36k dinner. RM paid 205k. AJ owes RM net.
  ),
];

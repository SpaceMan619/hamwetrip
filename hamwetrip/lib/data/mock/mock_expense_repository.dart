import 'dart:async';

import '../../data/models/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../features/shakira/data/demo/mock_expenses.dart';

/// In-memory [ExpenseRepository] backed by the existing mock data.
class MockExpenseRepository implements ExpenseRepository {
  List<Expense> _expenses = List.from(mockExpenses);
  List<Balance> _balances = List.from(mockBalances);
  final _expenseControllers = <StreamController<List<Expense>>>[];
  final _balanceControllers = <StreamController<List<Balance>>>[];

  @override
  Stream<List<Expense>> watchExpenses(String tripId) {
    final controller = StreamController<List<Expense>>();
    _expenseControllers.add(controller);
    controller.add(List.from(_expenses.reversed));
    return controller.stream;
  }

  @override
  Stream<List<Balance>> watchBalances(String tripId) {
    final controller = StreamController<List<Balance>>();
    _balanceControllers.add(controller);
    controller.add(List.from(_balances));
    return controller.stream;
  }

  void _notifyExpenses() {
    for (final c in _expenseControllers) {
      if (!c.isClosed) c.add(List.from(_expenses.reversed));
    }
  }

  void _notifyBalances() {
    for (final c in _balanceControllers) {
      if (!c.isClosed) c.add(List.from(_balances));
    }
  }

  @override
  Future<Expense> createExpense({
    required String tripId,
    required String description,
    required double amount,
    required String paidByInitials,
    required String paidByName,
    required String categoryEmoji,
    required String category,
    required List<String> splitAmongInitials,
  }) async {
    final expense = Expense(
      id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
      description: description,
      amount: amount,
      paidByInitials: paidByInitials,
      paidByName: paidByName,
      categoryEmoji: categoryEmoji,
      category: category,
      splitAmongInitials: splitAmongInitials,
      date: DateTime.now(),
    );
    _expenses = [..._expenses, expense];
    _notifyExpenses();
    return expense;
  }

  @override
  Future<void> settleExpense({
    required String tripId,
    required String expenseId,
  }) async {
    _expenses = _expenses.where((e) => e.id != expenseId).toList();
    _notifyExpenses();
  }

  @override
  Future<void> settleBalance({
    required String tripId,
    required Balance balance,
  }) async {
    _balances = _balances
        .where(
          (b) =>
              !(b.fromInitials == balance.fromInitials &&
                  b.toInitials == balance.toInitials),
        )
        .toList();
    _notifyBalances();
  }

  @override
  Future<void> deleteExpense({
    required String tripId,
    required String expenseId,
  }) async {
    _expenses = _expenses.where((e) => e.id != expenseId).toList();
    _notifyExpenses();
  }

  void dispose() {
    for (final c in _expenseControllers) {
      if (!c.isClosed) c.close();
    }
    for (final c in _balanceControllers) {
      if (!c.isClosed) c.close();
    }
  }
}

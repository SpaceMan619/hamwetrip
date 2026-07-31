import '../../data/models/expense.dart';

/// Expenses and balances for the expense-splitting screen.
abstract interface class ExpenseRepository {
  /// All expenses for a trip, live-updated.
  Stream<List<Expense>> watchExpenses(String tripId);

  /// All outstanding balances for a trip, live-updated.
  Stream<List<Balance>> watchBalances(String tripId);

  /// Creates a new expense.
  Future<Expense> createExpense({
    required String tripId,
    required String description,
    required double amount,
    required String paidByInitials,
    required String paidByName,
    required String categoryEmoji,
    required String category,
    required List<String> splitAmongInitials,
  });

  /// Marks an expense as settled.
  Future<void> settleExpense({
    required String tripId,
    required String expenseId,
  });

  /// Marks a balance as settled.
  Future<void> settleBalance({
    required String tripId,
    required Balance balance,
  });

  /// Deletes an expense.
  Future<void> deleteExpense({
    required String tripId,
    required String expenseId,
  });
}

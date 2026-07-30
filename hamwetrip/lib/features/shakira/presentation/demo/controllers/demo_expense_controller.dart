import 'package:flutter/foundation.dart';
import '../../../../../data/models/expense.dart';
import '../../../../../features/shakira/data/demo/mock_expenses.dart';

class DemoExpenseController extends ChangeNotifier {
  final List<Expense> _allExpenses = List.from(mockExpenses);
  final List<Balance> _allBalances = List.from(mockBalances);

  // UI State tracked here since the models don't have isSettled/isPaid fields
  final Set<String> _settledExpenseIds = {};
  final Set<String> _settledBalanceKeys = {};

  String? _searchQuery;
  String _filterCategory = 'All';

  List<Expense> get expenses => _filteredExpenses;
  List<Balance> get pendingBalances => _allBalances
      .where(
        (b) =>
            !_settledBalanceKeys.contains('${b.fromInitials}-${b.toInitials}'),
      )
      .toList();

  List<String> get categories => [
    'All',
    'Transport',
    'Food',
    'Activity',
    'Tips',
    'Other',
  ];

  double get totalSpent => _allExpenses.fold(0.0, (sum, e) => sum + e.amount);
  double get totalOwed => pendingBalances.fold(0.0, (sum, b) => sum + b.amount);
  int get pendingSettlementCount => pendingBalances.length;

  List<Expense> get _filteredExpenses {
    var result = _allExpenses.toList();
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final q = _searchQuery!.toLowerCase();
      result = result
          .where(
            (e) =>
                e.description.toLowerCase().contains(q) ||
                e.paidByName.toLowerCase().contains(q),
          )
          .toList();
    }
    if (_filterCategory != 'All') {
      result = result.where((e) => e.category == _filterCategory).toList();
    }
    // Show newest first
    return result.reversed.toList();
  }

  bool isExpenseSettled(String id) => _settledExpenseIds.contains(id);

  // ──────────────────────────────────────────────
  // Actions (Fixes "Empty Handlers" issue)
  // ──────────────────────────────────────────────

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = null;
    notifyListeners();
  }

  void setCategory(String category) {
    _filterCategory = category;
    notifyListeners();
  }

  void markExpenseSettled(String expenseId) {
    if (_settledExpenseIds.contains(expenseId)) return;
    _settledExpenseIds.add(expenseId);
    notifyListeners();
  }

  void settleBalance(Balance balance) {
    final key = '${balance.fromInitials}-${balance.toInitials}';
    if (_settledBalanceKeys.contains(key)) return;
    _settledBalanceKeys.add(key);
    notifyListeners();
  }

  void deleteExpense(String expenseId) {
    _allExpenses.removeWhere((e) => e.id == expenseId);
    notifyListeners();
  }
}

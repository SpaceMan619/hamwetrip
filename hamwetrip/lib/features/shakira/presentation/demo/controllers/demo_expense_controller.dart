import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../../../core/error/app_error.dart';
import '../../../../../data/models/expense.dart';
import '../../../../../domain/repositories/expense_repository.dart';

class DemoExpenseController extends ChangeNotifier {
  final ExpenseRepository _repository;
  final String tripId;

  List<Expense> _allExpenses = [];
  List<Balance> _allBalances = [];
  final Set<String> _settledBalanceKeys = {};

  bool _isLoading = true;
  AppError? _error;
  String? _searchQuery;
  String _filterCategory = 'All';
  StreamSubscription<List<Expense>>? _expenseSub;
  StreamSubscription<List<Balance>>? _balanceSub;

  DemoExpenseController({
    required ExpenseRepository repository,
    this.tripId = 'demo-trip',
  }) : _repository = repository {
    _loadData();
  }

  // ──────────────────────────────────────────────
  // Loading & error state
  // ──────────────────────────────────────────────

  bool get isLoading => _isLoading;
  AppError? get error => _error;
  bool get hasError => _error != null;

  // ──────────────────────────────────────────────
  // Data accessors
  // ──────────────────────────────────────────────

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
    return result.reversed.toList();
  }

  // ──────────────────────────────────────────────
  // Stream subscription
  // ──────────────────────────────────────────────

  void _loadData() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _expenseSub = _repository
        .watchExpenses(tripId)
        .listen(
          (expenses) {
            _allExpenses = expenses;
            _isLoading = false;
            notifyListeners();
          },
          onError: (Object error) {
            _isLoading = false;
            _error = error is AppError
                ? error
                : const UnknownError(message: 'Failed to load expenses.');
            notifyListeners();
          },
        );

    _balanceSub = _repository
        .watchBalances(tripId)
        .listen(
          (balances) {
            _allBalances = balances;
            notifyListeners();
          },
          onError: (Object error) {
            _isLoading = false;
            _error = error is AppError
                ? error
                : const UnknownError(message: 'Failed to load balances.');
            notifyListeners();
          },
        );
  }

  Future<void> retry() async {
    await _expenseSub?.cancel();
    await _balanceSub?.cancel();
    _loadData();
  }

  // ──────────────────────────────────────────────
  // Actions
  // ──────────────────────────────────────────────

  final Set<String> _settledExpenseIds = {};

  bool isExpenseSettled(String id) => _settledExpenseIds.contains(id);

  void markExpenseSettled(String expenseId) {
    if (_settledExpenseIds.contains(expenseId)) return;
    _settledExpenseIds.add(expenseId);
    notifyListeners();
  }

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

  Future<void> settleBalance(Balance balance) async {
    try {
      final key = '${balance.fromInitials}-${balance.toInitials}';
      _settledBalanceKeys.add(key);
      notifyListeners();
      await _repository.settleBalance(tripId: tripId, balance: balance);
    } on AppError catch (e) {
      _error = e;
      notifyListeners();
    } catch (e) {
      _error = UnknownError(cause: e);
      notifyListeners();
    }
  }

  /// Records an expense and lets the watch stream bring it back, for the same
  /// reason [DemoVotingController.createPoll] does: one path into the list.
  ///
  /// Returns false and records the error if the write is refused.
  Future<bool> createExpense({
    required String description,
    required double amount,
    required String category,
    required String categoryEmoji,
    required String paidByInitials,
    required String paidByName,
    required List<String> splitAmongInitials,
  }) async {
    try {
      await _repository.createExpense(
        tripId: tripId,
        description: description.trim(),
        amount: amount,
        paidByInitials: paidByInitials,
        paidByName: paidByName,
        categoryEmoji: categoryEmoji,
        category: category,
        splitAmongInitials: splitAmongInitials,
      );
      return true;
    } on AppError catch (e) {
      _error = e;
      notifyListeners();
      return false;
    } catch (e) {
      _error = UnknownError(cause: e);
      notifyListeners();
      return false;
    }
  }

  /// Returns whether the delete succeeded, so a caller can tell that apart
  /// from a stale [error] left over from some earlier action rather than
  /// this one.
  Future<bool> deleteExpense(String expenseId) async {
    try {
      await _repository.deleteExpense(tripId: tripId, expenseId: expenseId);
      return true;
    } on AppError catch (e) {
      _error = e;
      notifyListeners();
      return false;
    } catch (e) {
      _error = UnknownError(cause: e);
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _expenseSub?.cancel();
    _balanceSub?.cancel();
    super.dispose();
  }
}

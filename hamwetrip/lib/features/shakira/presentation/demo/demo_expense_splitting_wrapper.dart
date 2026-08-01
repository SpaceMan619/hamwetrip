import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../app/app_routes.dart';
import '../../../../data/models/expense.dart';
import '../../../../data/models/settlement_args.dart';
import '../expense_splitting_screen.dart';
import 'controllers/demo_expense_controller.dart';
import '../../../../core/state/view_state.dart';
import '../../../../core/widgets/create_forms.dart';
import '../../../../core/widgets/hamwe_bottom_navigation.dart';
import '../../../../core/widgets/trip_scoped.dart';
import '../../../home/home_providers.dart';
import '../../../trips/trip_providers.dart';

/// Wires up expense data from Firestore to the pure UI screen.
class DemoExpenseSplittingWrapper extends StatelessWidget {
  const DemoExpenseSplittingWrapper({super.key});

  @override
  Widget build(BuildContext context) => TripScoped(
    destination: HamweDestination.ledger,
    builder: (tripId) =>
        _ExpenseSplittingView(key: ValueKey(tripId), tripId: tripId),
  );
}

class _ExpenseSplittingView extends ConsumerStatefulWidget {
  const _ExpenseSplittingView({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<_ExpenseSplittingView> createState() =>
      _DemoExpenseSplittingWrapperState();
}

class _DemoExpenseSplittingWrapperState
    extends ConsumerState<_ExpenseSplittingView> {
  late final DemoExpenseController _controller;

  // Current demo user is RM (Rajveer Malik)
  static const String _currentUserId = 'RM';

  @override
  void initState() {
    super.initState();
    _controller = DemoExpenseController(
      repository: ref.read(expenseRepositoryProvider),
      tripId: widget.tripId,
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addExpense() async {
    final input = await showAddExpenseForm(context);
    if (input == null || !mounted) return;

    // Split across whoever is actually in the trip, taken from the roster
    // rather than assumed, so the figures match the membership.
    final membersState = ref.read(tripMembersControllerProvider(widget.tripId));
    final splitAmong = switch (membersState.view) {
      ViewData(:final data) =>
        data.map((member) => member.initials).toList(growable: false),
      _ => const <String>[],
    };

    final profileState = ref.read(currentUserProfileProvider);
    final profile = switch (profileState.view) {
      ViewData(:final data) => data,
      _ => null,
    };
    final paidByName = profile?.displayName ?? 'You';
    final paidByInitials = profile?.initials ?? _currentUserId;

    final created = await _controller.createExpense(
      description: input.description,
      amount: input.amount,
      category: input.category,
      categoryEmoji: input.categoryEmoji,
      paidByInitials: paidByInitials,
      paidByName: paidByName,
      splitAmongInitials: splitAmong.isEmpty ? [paidByInitials] : splitAmong,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          created
              ? 'Expense added'
              : _controller.error?.message ?? 'Could not add the expense',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: created ? AppColors.forest : null,
      ),
    );
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete expense?',
      message:
          '"${expense.description}" will be removed for everyone on '
          "this trip. This can't be undone.",
    );
    if (!confirmed || !mounted) return;

    final deleted = await _controller.deleteExpense(expense.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'Expense deleted'
              : _controller.error?.message ?? 'Could not delete the expense',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: deleted ? AppColors.forest : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_controller.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.warmSand,
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: const HamweBottomNavigation(
          selected: HamweDestination.ledger,
        ),
      );
    }

    // Error state
    if (_controller.hasError) {
      return Scaffold(
        backgroundColor: AppColors.warmSand,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _controller.error?.message ?? 'Something went wrong',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _controller.retry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const HamweBottomNavigation(
          selected: HamweDestination.ledger,
        ),
      );
    }

    // Calculate what "you" (RM) owe and are owed based on balances
    double youOwe = 0;
    double youAreOwed = 0;

    for (final balance in _controller.pendingBalances) {
      if (balance.fromInitials == _currentUserId) {
        youOwe += balance.amount;
      } else if (balance.toInitials == _currentUserId) {
        youAreOwed += balance.amount;
      }
    }

    return ExpenseSplittingScreen(
      expenses: _controller.expenses,
      balances: _controller.pendingBalances,
      totalSpent: _controller.totalSpent,
      youOwe: youOwe,
      youAreOwed: youAreOwed,
      bottomNavigation: const HamweBottomNavigation(
        selected: HamweDestination.ledger,
      ),
      onAddExpense: _addExpense,
      onDeleteExpense: _deleteExpense,
      onExpenseTap: (expense) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${expense.categoryEmoji} ${expense.description} — Split ${expense.splitAmongInitials.length} ways',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onSettleUp: (balance) {
        final settlementArgs = SettlementArgs(
          balance: balance,
          maskedPhone:
              '*** *** ${balance.toInitials.hashCode.abs() % 900 + 100}',
          referenceId: 'MTN-${DateTime.now().millisecondsSinceEpoch}',
        );

        Navigator.of(context)
            .pushNamed(
              AppRoutes.settlementConfirmation,
              arguments: settlementArgs,
            )
            .then((_) {
              _controller.settleBalance(balance);
            });
      },
      onRemindEveryone: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('MoMo payment reminders sent to all members!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onOpenMomoSummary: () {
        Navigator.of(context).pushNamed(AppRoutes.momoSummary);
      },
    );
  }
}

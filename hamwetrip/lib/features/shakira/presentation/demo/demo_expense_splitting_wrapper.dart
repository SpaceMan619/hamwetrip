import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../app/app_routes.dart';
import '../../../../../data/models/settlement_args.dart';
import '../expense_splitting_screen.dart';
import 'controllers/demo_expense_controller.dart';
import '../../../../../core/widgets/hamwe_bottom_navigation.dart';

/// Wires up mock expense data and local state to your pure UI screen.
class DemoExpenseSplittingWrapper extends StatefulWidget {
  const DemoExpenseSplittingWrapper({super.key});

  @override
  State<DemoExpenseSplittingWrapper> createState() =>
      _DemoExpenseSplittingWrapperState();
}

class _DemoExpenseSplittingWrapperState
    extends State<DemoExpenseSplittingWrapper> {
  late final DemoExpenseController _controller;

  // Current demo user is RM (Rajveer Malik)
  static const String _currentUserId = 'RM';

  @override
  void initState() {
    super.initState();
    _controller = DemoExpenseController();
    _controller.addListener(
      () => setState(() {}),
    ); // Rebuild UI on state change
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

      // Fixes "Empty Handler" - Add Expense button
      onAddExpense: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Expense form submitted! (Demo mode - not persisted to backend)',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.forest,
          ),
        );
      },

      // Fixes "Empty Handler" - Tapping an expense card
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

      // Fixes "Empty Handler" - Settle up button (NOW NAVIGATES!)
      onSettleUp: (balance) {
        // Create the arguments expected by the settlement screen
        final settlementArgs = SettlementArgs(
          balance: balance,
          maskedPhone:
              '*** *** ${balance.toInitials.hashCode.abs() % 900 + 100}', // Fake masked phone
          referenceId: 'MTN-${DateTime.now().millisecondsSinceEpoch}',
        );

        // Navigate to the settlement confirmation screen
        Navigator.of(context)
            .pushNamed(
              AppRoutes.settlementConfirmation,
              arguments: settlementArgs,
            )
            .then((_) {
              // After coming back from settlement, mark as settled locally
              _controller.settleBalance(balance);
            });
      },

      // Fixes "Empty Handler" - Remind Everyone button
      onRemindEveryone: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('MoMo payment reminders sent to all members! (Demo)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/expense.dart';
import '../../../core/widgets/shakira_widgets/expense_card.dart';
import '../../../core/widgets/shakira_widgets/settlement_card.dart';

class ExpenseSplittingScreen extends StatelessWidget {
  final List<Expense> expenses;
  final List<Balance> balances;
  final double totalSpent;
  final double youOwe;
  final double youAreOwed;
  final VoidCallback onAddExpense;
  final void Function(Expense) onExpenseTap;
  final void Function(Balance) onSettleUp;
  final VoidCallback onRemindEveryone;

  const ExpenseSplittingScreen({
    super.key,
    required this.expenses,
    required this.balances,
    required this.totalSpent,
    required this.youOwe,
    required this.youAreOwed,
    required this.onAddExpense,
    required this.onExpenseTap,
    required this.onSettleUp,
    required this.onRemindEveryone,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.warmSand,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Text('Expenses'),
          bottom: const TabBar(
            indicatorColor: AppColors.forest,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
            unselectedLabelStyle: TextStyle(color: AppColors.muted),
            tabs: [
              Tab(text: 'Expenses'),
              Tab(text: 'Settlements'),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              color: Colors.white,
              child: Row(
                children: [
                  _SummaryBox(
                    title: 'Total Spent',
                    value: '\$${totalSpent.toStringAsFixed(2)}',
                    color: AppColors.sand,
                    textColor: AppColors.ink,
                  ),
                  const SizedBox(width: 12),
                  _SummaryBox(
                    title: 'You Owe',
                    value: '\$${youOwe.toStringAsFixed(2)}',
                    color: AppColors.paleSunset,
                    textColor: AppColors.sunset,
                  ),
                  const SizedBox(width: 12),
                  _SummaryBox(
                    title: 'You Are Owed',
                    value: '\$${youAreOwed.toStringAsFixed(2)}',
                    color: AppColors.paleMint,
                    textColor: AppColors.forest,
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // PASS DATA DIRECTLY TO THE TAB WIDGETS
                  _ExpensesTab(expenses: expenses, onExpenseTap: onExpenseTap),
                  _SettlementsTab(
                    balances: balances,
                    onSettleUp: onSettleUp,
                    onRemindEveryone: onRemindEveryone,
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: onAddExpense,
          backgroundColor: AppColors.forest,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add Expense',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title, value;
  final Color color, textColor;
  const _SummaryBox({
    required this.title,
    required this.value,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// SAFE TAB 1: Receives data via constructor
class _ExpensesTab extends StatelessWidget {
  final List<Expense> expenses;
  final void Function(Expense) onExpenseTap;

  const _ExpensesTab({required this.expenses, required this.onExpenseTap});

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Center(
        child: Text(
          'No expenses yet',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return ExpenseCard(
          expense: expense,
          onTap: () => onExpenseTap(expense),
        );
      },
    );
  }
}

// SAFE TAB 2: Receives data via constructor
class _SettlementsTab extends StatelessWidget {
  final List<Balance> balances;
  final void Function(Balance) onSettleUp;
  final VoidCallback onRemindEveryone;

  const _SettlementsTab({
    required this.balances,
    required this.onSettleUp,
    required this.onRemindEveryone,
  });

  @override
  Widget build(BuildContext context) {
    if (balances.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppColors.forest),
            SizedBox(height: 16),
            Text(
              'All settled up!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Simplify Debts',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 16),
        ...balances.map(
          (b) => SettlementCard(balance: b, onSettleUp: () => onSettleUp(b)),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: onRemindEveryone,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Remind Everyone'),
          ),
        ),
      ],
    );
  }
}

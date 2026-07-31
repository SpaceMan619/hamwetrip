import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/expense.dart';
import '../../../core/widgets/shakira_widgets/expense_card.dart';
import '../../../core/widgets/shakira_widgets/settlement_card.dart';
import '../../../core/util/currency_format.dart';

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
  final VoidCallback onOpenMomoSummary;
  final Widget? bottomNavigation;

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
    required this.onOpenMomoSummary,
    this.bottomNavigation,
  });

  @override
  Widget build(BuildContext context) {
    // keep the three ledger views on one tab controller.
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.warmSand,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text('Expenses'),
          actions: [
            IconButton(
              tooltip: 'MoMo payment summary',
              onPressed: onOpenMomoSummary,
              icon: const Icon(Icons.phone_android_outlined),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.forest,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
            unselectedLabelStyle: TextStyle(color: AppColors.muted),
            tabs: [
              Tab(text: 'History'),
              Tab(text: 'Add Expense'),
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
                    value: formatRwfCompact(totalSpent),
                    color: AppColors.sand,
                    textColor: AppColors.ink,
                  ),
                  const SizedBox(width: 12),
                  _SummaryBox(
                    title: 'You Owe',
                    value: formatRwfCompact(youOwe),
                    color: AppColors.paleSunset,
                    textColor: AppColors.sunset,
                  ),
                  const SizedBox(width: 12),
                  _SummaryBox(
                    title: 'You Are Owed',
                    value: formatRwfCompact(youAreOwed),
                    color: AppColors.paleMint,
                    textColor: AppColors.forest,
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // SAFE INJECTION: Pass data directly via constructor
                  _ExpensesTab(expenses: expenses, onExpenseTap: onExpenseTap),
                  _AddExpenseTab(onSubmit: onAddExpense),
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
        bottomNavigationBar: bottomNavigation,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => DefaultTabController.of(context).animateTo(1),
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
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Existing Tabs (Rewritten Safely) ---
class _ExpensesTab extends StatelessWidget {
  final List<Expense> expenses;
  final void Function(Expense) onExpenseTap;

  const _ExpensesTab({required this.expenses, required this.onExpenseTap});

  @override
  Widget build(BuildContext context) {
    // render the supplied history list without owning its data source.
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
    // render pending balances and send settlement actions to the wrapper.
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

// --- NEW: Add Expense Tab (Matches Figma perfectly) ---
class _AddExpenseTab extends StatefulWidget {
  final VoidCallback onSubmit;
  const _AddExpenseTab({required this.onSubmit});

  @override
  State<_AddExpenseTab> createState() => _AddExpenseTabState();
}

class _AddExpenseTabState extends State<_AddExpenseTab> {
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  String _selectedCategory = 'Food';
  bool _payViaMoMo = true;

  final List<String> _categories = ['Fuel', 'Food', 'Entry Fees'];
  final List<String> _splitWith = ['Kamanzi', 'Umuhozza', 'Jean', 'Malik'];

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // collect a new expense before passing the save action upward.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AMOUNT (RWF)',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 7),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '0.00',
              filled: true,
              fillColor: AppColors.warmSand,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                borderSide: BorderSide(color: AppColors.line, width: 2),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                borderSide: BorderSide(color: AppColors.forest, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'What was it for?',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 7),
          TextField(
            controller: _purposeController,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.warmSand,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                borderSide: BorderSide(color: AppColors.line, width: 2),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                borderSide: BorderSide(color: AppColors.forest, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'CATEGORY',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final icon = cat == 'Fuel'
                  ? Icons.local_gas_station
                  : cat == 'Food'
                  ? Icons.restaurant
                  : Icons.receipt_long;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedCategory == cat
                        ? AppColors.forest.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: _selectedCategory == cat
                        ? Border.all(color: AppColors.forest, width: 1.5)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: _selectedCategory == cat
                            ? AppColors.forest
                            : AppColors.muted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cat,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _selectedCategory == cat
                              ? AppColors.forest
                              : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'SPLIT WITH…',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _splitWith
                .map(
                  (name) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warmSand,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.forest,
                          child: Text(
                            name[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.line, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.phone_android_outlined, color: AppColors.forest),
                    SizedBox(width: 8),
                    Text(
                      'Pay via MoMo',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _payViaMoMo,
                  activeThumbColor: AppColors.forest,
                  onChanged: (val) => setState(() => _payViaMoMo = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Submit Button (Primary Style)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onSubmit();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Save Expense'),
            ),
          ),
        ],
      ),
    );
  }
}

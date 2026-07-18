import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../widgets/expense_card.dart';
import '../widgets/settlement_card.dart';

class ExpenseSplittingScreen extends StatefulWidget {
  const ExpenseSplittingScreen({super.key});

  @override
  State<ExpenseSplittingScreen> createState() => _ExpenseSplittingScreenState();
}

class _ExpenseSplittingScreenState extends State<ExpenseSplittingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // --- Mock Data ---
  // FIX: Removed 'const' from the list because DateTime.now() runs at runtime
  final List<Expense> _expenses = [
    Expense(
      id: 'e1',
      description: 'Heaven Restaurant Dinner',
      amount: 120.00,
      paidByInitials: 'JP',
      paidByName: 'Jean Pierre',
      categoryEmoji: '🍽️',
      category: 'Food',
      splitAmongInitials: const ['JP', 'AM', 'CN', 'PD'],
      date: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Expense(
      id: 'e2',
      description: 'Gorilla Trekking Permits',
      amount: 1500.00,
      paidByInitials: 'AM',
      paidByName: 'Alice Mugisha',
      categoryEmoji: '🦍',
      category: 'Activity',
      splitAmongInitials: const ['JP', 'AM', 'CN', 'PD', 'SK', 'LM'],
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Expense(
      id: 'e3',
      description: 'Fuel for Kigali to Musanze',
      amount: 45.50,
      paidByInitials: 'CN',
      paidByName: 'Claude Niyonsaba',
      categoryEmoji: '⛽',
      category: 'Transport',
      splitAmongInitials: const ['JP', 'AM', 'CN'],
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Expense(
      id: 'e4',
      description: 'Five Volcanoes Hotel Stay',
      amount: 450.00,
      paidByInitials: 'SK',
      paidByName: 'Sarah Kim',
      categoryEmoji: '🏨',
      category: 'Accommodation',
      splitAmongInitials: const [
        'JP',
        'AM',
        'CN',
        'PD',
        'SK',
        'LM',
        'RT',
        'BG',
      ],
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  final List<Balance> _balances = const [
    Balance(
      fromInitials: 'JP',
      fromName: 'Jean Pierre',
      toInitials: 'AM',
      toName: 'Alice Mugisha',
      amount: 245.50,
    ),
    Balance(
      fromInitials: 'CN',
      fromName: 'Claude N.',
      toInitials: 'SK',
      toName: 'Sarah Kim',
      amount: 89.20,
    ),
  ];

  double get _totalSpent => _expenses.fold(0, (sum, e) => sum + e.amount);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleAddExpense() {
    debugPrint('Add expense tapped');
  }

  void _handleSettleUp(Balance balance) {
    debugPrint('Settle up tapped: ${balance.fromName} pays ${balance.toName}');
  }

  void _handleExpenseTap(Expense expense) {
    debugPrint('Tapped on expense: ${expense.description}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width > 600;
    final horizontalPadding = isTablet ? 40.0 : 20.0;
    final maxWidth = isTablet ? 700.0 : double.infinity;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        title: const Text('Expenses'),
        actions: [
          IconButton(
            onPressed: () {}, // Placeholder
            icon: const Icon(Icons.filter_list_outlined),
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 20,
            ),
            color: colorScheme.surface,
            child: Row(
              children: [
                _SummaryBox(
                  title: 'Total Spent',
                  value: '\$${_totalSpent.toStringAsFixed(2)}',
                  colorScheme: colorScheme,
                  theme: theme,
                ),
                const SizedBox(width: 12),
                _SummaryBox(
                  title: 'You Owe',
                  value: '\$245.50',
                  colorScheme: colorScheme,
                  theme: theme,
                  isOwe: true,
                ),
                const SizedBox(width: 12),
                _SummaryBox(
                  title: 'You Are Owed',
                  value: '\$0.00',
                  colorScheme: colorScheme,
                  theme: theme,
                  isOwed: true,
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withOpacity(0.4),
          ),

          // Tabs
          Container(
            color: colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              dividerColor: colorScheme.outlineVariant.withOpacity(0.4),
              tabs: const [
                Tab(text: 'Expenses'),
                Tab(text: 'Settlements'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ExpensesTab(
                  expenses: _expenses,
                  padding: horizontalPadding,
                  maxWidth: maxWidth,
                  onTap: _handleExpenseTap,
                ),
                _SettlementsTab(
                  balances: _balances,
                  padding: horizontalPadding,
                  maxWidth: maxWidth,
                  onSettleUp: _handleSettleUp,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleAddExpense,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }
}

// --- Helper Widgets ---

class _SummaryBox extends StatelessWidget {
  final String title;
  final String value;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool isOwe;
  final bool isOwed;

  const _SummaryBox({
    required this.title,
    required this.value,
    required this.colorScheme,
    required this.theme,
    this.isOwe = false,
    this.isOwed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOwe
              ? colorScheme.errorContainer.withOpacity(0.4)
              : isOwed
              ? colorScheme.primaryContainer.withOpacity(0.4)
              : colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isOwe
                    ? colorScheme.error
                    : isOwed
                    ? colorScheme.primary
                    : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpensesTab extends StatelessWidget {
  final List<Expense> expenses;
  final double padding;
  final double maxWidth;
  final void Function(Expense) onTap;

  const _ExpensesTab({
    required this.expenses,
    required this.padding,
    required this.maxWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            return ExpenseCard(
              expense: expenses[index],
              onTap: () => onTap(expenses[index]),
            );
          },
        ),
      ),
    );
  }
}

class _SettlementsTab extends StatelessWidget {
  final List<Balance> balances;
  final double padding;
  final double maxWidth;
  final void Function(Balance) onSettleUp;

  const _SettlementsTab({
    required this.balances,
    required this.padding,
    required this.maxWidth,
    required this.onSettleUp,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    if (balances.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'All settled up!',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
          children: [
            Text(
              'Simplify Debts',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'These are the minimum transactions needed to settle all balances.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ...balances.map(
              (b) =>
                  SettlementCard(balance: b, onSettleUp: () => onSettleUp(b)),
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: () => debugPrint('Settle all tapped'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Remind Everyone'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

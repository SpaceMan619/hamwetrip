import 'package:flutter/material.dart';
import '../models/momo_transaction.dart';
import '../widgets/momo_transaction_tile.dart';

class MomoSummaryScreen extends StatefulWidget {
  const MomoSummaryScreen({super.key});

  @override
  State<MomoSummaryScreen> createState() => _MomoSummaryScreenState();
}

class _MomoSummaryScreenState extends State<MomoSummaryScreen> {
  // 0 = To Send, 1 = To Receive
  int _selectedSegment = 0;

  // --- Mock Data ---
  final List<MomoTransaction> _transactions = [
    const MomoTransaction(
      id: 'm1',
      name: 'Alice Mugisha',
      initials: 'AM',
      maskedPhone: '078X-XXX-456',
      amount: 245.50,
      type: MomoType.send,
      status: MomoStatus.pending,
    ),
    const MomoTransaction(
      id: 'm2',
      name: 'Sarah Kim',
      initials: 'SK',
      maskedPhone: '073X-XXX-890',
      amount: 89.20,
      type: MomoType.send,
      status: MomoStatus.pending,
    ),
    const MomoTransaction(
      id: 'm3',
      name: 'Claude Niyonsaba',
      initials: 'CN',
      maskedPhone: '079X-XXX-123',
      amount: 150.00,
      type: MomoType.receive,
      status: MomoStatus.pending,
    ),
    const MomoTransaction(
      id: 'm4',
      name: 'Jean Pierre',
      initials: 'JP',
      maskedPhone: '078X-XXX-789',
      amount: 50.00,
      type: MomoType.send,
      status: MomoStatus.completed,
    ),
    const MomoTransaction(
      id: 'm5',
      name: 'Patrick D.',
      initials: 'PD',
      maskedPhone: '072X-XXX-456',
      amount: 120.00,
      type: MomoType.receive,
      status: MomoStatus.pending,
    ),
  ];

  List<MomoTransaction> get _toSend =>
      _transactions.where((t) => t.type == MomoType.send).toList();

  List<MomoTransaction> get _toReceive =>
      _transactions.where((t) => t.type == MomoType.receive).toList();

  double get _totalToSend => _toSend
      .where((t) => t.status == MomoStatus.pending)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalToReceive => _toReceive
      .where((t) => t.status == MomoStatus.pending)
      .fold(0.0, (sum, t) => sum + t.amount);

  void _handlePayNow(MomoTransaction transaction) {
    debugPrint(
      'Initiate MoMo to ${transaction.name} (${transaction.maskedPhone})',
    );
  }

  void _handleRequest(MomoTransaction transaction) {
    debugPrint('Request MoMo from ${transaction.name}');
  }

  void _handleSendAll() {
    debugPrint('Batch send all pending: \$${_totalToSend.toStringAsFixed(2)}');
  }

  void _handleRequestAll() {
    debugPrint(
      'Batch request all pending: \$${_totalToReceive.toStringAsFixed(2)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width > 600;
    final horizontalPadding = isTablet ? 40.0 : 20.0;
    final maxWidth = isTablet ? 700.0 : double.infinity;

    final currentList = _selectedSegment == 0 ? _toSend : _toReceive;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        title: const Text('MoMo Summary'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.history_outlined),
            tooltip: 'History',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Summary Cards
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 20,
            ),
            color: colorScheme.surface,
            child: Row(
              children: [
                _SummaryPill(
                  title: 'To Send',
                  amount: _totalToSend,
                  colorScheme: colorScheme,
                  theme: theme,
                  isSend: true,
                ),
                const SizedBox(width: 12),
                _SummaryPill(
                  title: 'To Receive',
                  amount: _totalToReceive,
                  colorScheme: colorScheme,
                  theme: theme,
                  isSend: false,
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withOpacity(0.4),
          ),

          // Segmented Button Control (FIXED FOR FLUTTER 3.22+)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16,
            ),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('To Send'),
                  icon: Icon(Icons.north_east, size: 18),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('To Receive'),
                  icon: Icon(Icons.south_west, size: 18),
                ),
              ],
              // FIX 1: Changed to 'selected' and passed a Set
              selected: {_selectedSegment},
              // FIX 2: Update callback to accept a Set
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  _selectedSegment = newSelection.first;
                });
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.comfortable,
                // FIX 3: Updated to WidgetStatePropertyAll (replaces deprecated MaterialStatePropertyAll)
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          // Transaction List
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  itemCount: currentList.length,
                  itemBuilder: (context, index) {
                    final tx = currentList[index];
                    return MomoTransactionTile(
                      transaction: tx,
                      onAction: tx.status == MomoStatus.pending
                          ? () {
                              if (tx.type == MomoType.send) {
                                _handlePayNow(tx);
                              } else {
                                _handleRequest(tx);
                              }
                            }
                          : null,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      // Floating Action based on current tab
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedSegment == 0 ? _handleSendAll : _handleRequestAll,
        icon: Icon(_selectedSegment == 0 ? Icons.send : Icons.download),
        label: Text(
          _selectedSegment == 0
              ? 'Send All (\$${_totalToSend.toStringAsFixed(0)})'
              : 'Request All (\$${_totalToReceive.toStringAsFixed(0)})',
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// --- Helper Widget ---

class _SummaryPill extends StatelessWidget {
  final String title;
  final double amount;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool isSend;

  const _SummaryPill({
    required this.title,
    required this.amount,
    required this.colorScheme,
    required this.theme,
    required this.isSend,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSend
              ? colorScheme.errorContainer.withOpacity(0.5)
              : colorScheme.primaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: isSend ? colorScheme.error : colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

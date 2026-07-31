import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/momo_transaction.dart';
import '../../../core/widgets/shakira_widgets/momo_transaction_tile.dart';

class MomoSummaryScreen extends StatelessWidget {
  final List<MomoTransaction> toSend;
  final List<MomoTransaction> toReceive;
  final double totalSendAmount;
  final double totalReceiveAmount;
  final void Function(MomoTransaction) onPayNow;
  final void Function(MomoTransaction) onRequest;
  final String fabLabel;
  final VoidCallback onFabTap;
  final Widget? bottomNavigation;

  const MomoSummaryScreen({
    super.key,
    required this.toSend,
    required this.toReceive,
    required this.totalSendAmount,
    required this.totalReceiveAmount,
    required this.onPayNow,
    required this.onRequest,
    required this.fabLabel,
    required this.onFabTap,
    this.bottomNavigation,
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
          automaticallyImplyLeading: false,
          title: const Text('MoMo Summary'),
          bottom: const TabBar(
            indicatorColor: AppColors.forest,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
            unselectedLabelStyle: TextStyle(color: AppColors.muted),
            tabs: [
              Tab(text: 'To Send'),
              Tab(text: 'To Receive'),
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
                  _SummaryPill(
                    title: 'To Send',
                    amount: totalSendAmount,
                    isSend: true,
                  ),
                  const SizedBox(width: 12),
                  _SummaryPill(
                    title: 'To Receive',
                    amount: totalReceiveAmount,
                    isSend: false,
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // PASS DATA DIRECTLY TO THE TAB WIDGETS
                  _TransactionTab(transactions: toSend, onAction: onPayNow),
                  _TransactionTab(transactions: toReceive, onAction: onRequest),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: bottomNavigation,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: onFabTap,
          backgroundColor: AppColors.forest,
          icon: const Icon(Icons.send, color: Colors.white),
          label: Text(fabLabel, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String title;
  final double amount;
  final bool isSend;
  const _SummaryPill({
    required this.title,
    required this.amount,
    required this.isSend,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSend ? AppColors.paleSunset : AppColors.paleMint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'RWF ${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isSend ? AppColors.sunset : AppColors.forest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// SAFE TAB: Receives data via constructor instead of searching the widget tree
class _TransactionTab extends StatelessWidget {
  final List<MomoTransaction> transactions;
  final void Function(MomoTransaction) onAction;

  const _TransactionTab({required this.transactions, required this.onAction});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(
        child: Text(
          'No transactions',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return MomoTransactionTile(
          transaction: tx,
          onAction: tx.status == MomoStatus.pending ? () => onAction(tx) : null,
        );
      },
    );
  }
}

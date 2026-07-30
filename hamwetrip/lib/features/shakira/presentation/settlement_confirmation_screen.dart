import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/settlement_args.dart';

class SettlementConfirmationScreen extends StatelessWidget {
  final SettlementArgs args;
  final bool isProcessing;
  final VoidCallback onDone;
  final VoidCallback onShareReceipt;

  const SettlementConfirmationScreen({
    super.key,
    required this.args,
    required this.isProcessing,
    required this.onDone,
    required this.onShareReceipt,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          if (!isProcessing)
            IconButton(
              onPressed: onDone,
              icon: const Icon(Icons.close, color: AppColors.ink),
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Success Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isProcessing ? AppColors.sand : AppColors.paleMint,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isProcessing
                      ? const CircularProgressIndicator(color: AppColors.forest)
                      : const Icon(
                          Icons.check_rounded,
                          size: 50,
                          color: AppColors.forest,
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Status Texts
              const Text(
                'Settlement Confirmed',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              if (!isProcessing)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paleMint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'TRANSACTION SETTLED',
                    style: TextStyle(
                      color: AppColors.forest,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              if (isProcessing)
                Text(
                  'Processing payment...',
                  style: TextStyle(color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 32),

              // 3. High-Contrast Amount
              // 3. High-Contrast Amount
              Text(
                'RWF ${args.balance.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(height: 12),

              // 4. Recipient Info
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.forest,
                    child: Text(
                      args.balance.toInitials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Sent to ${args.balance.toName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // 5. Transaction Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.warmSand,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'TRANSACTION DETAILS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: 'Transaction Type',
                      value: 'Mobile Money Transaction',
                    ),
                    const Divider(height: 24, color: AppColors.line),
                    _DetailRow(label: 'Sent to', value: args.balance.toName),
                    const Divider(height: 24, color: AppColors.line),
                    _DetailRow(label: 'Phone', value: args.maskedPhone),
                    const Divider(height: 24, color: AppColors.line),
                    _DetailRow(
                      label: 'Reference ID',
                      value: args.referenceId,
                      isMono: true,
                    ), // Monospace for MoMo ref
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 6. Activity Timeline (Matching the Figma image exactly)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.line.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16, bottom: 12),
                      child: Text(
                        'ACTIVITY TIMELINE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    _TimelineStep(
                      time: '10:30 AM',
                      title: 'Payment Sent manually',
                      isDone: true,
                    ),
                    _TimelineStep(
                      time: '10:45 AM',
                      title: '${args.balance.toName} received notification',
                      isDone: true,
                    ),
                    _TimelineStep(
                      time: '11:15 AM',
                      title:
                          '${args.balance.toName} confirmed "Payment Received"',
                      isDone: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // 7. Back to Ledger Button (Secondary Style per Design System)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onDone,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.forest,
                    side: const BorderSide(
                      color: AppColors.forest,
                      width: 2,
                    ), // 2px border
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ), // 0.5rem radius
                  ),
                  child: const Text('Back to Ledger'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      // Note: HamweBottomNavigation goes here in the real app,
      // injected by the routing layer, not inside this screen file.
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final bool isMono;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isMono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
              fontSize: 14,
              fontFamily: isMono
                  ? 'monospace'
                  : null, // Monospace for MoMo reference
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String time;
  final String title;
  final bool isDone;

  const _TimelineStep({
    required this.time,
    required this.title,
    this.isDone = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left dot and line
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? AppColors.forest : AppColors.line,
                ),
              ),
              Container(
                width: 2,
                height: 24, // Height to connect to the next row
                color: AppColors.line,
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Right text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.ink,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
              const Text(
                'Settlement Confirmed',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isProcessing
                    ? 'Processing payment...'
                    : 'Balance updated successfully.',
                style: const TextStyle(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Text(
                '\$${args.balance.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.warmSand,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _DetailRow(label: 'Sent to', value: args.balance.toName),
                    const Divider(height: 32, color: AppColors.line),
                    _DetailRow(label: 'Phone', value: args.maskedPhone),
                    const Divider(height: 32, color: AppColors.line),
                    _DetailRow(label: 'Reference ID', value: args.referenceId),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              if (!isProcessing) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onDone,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Back to Expenses'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onShareReceipt,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.line),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Share Receipt'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 16)),
      Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
          fontSize: 16,
        ),
      ),
    ],
  );
}

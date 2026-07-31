import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/momo_transaction.dart';
import '../../../../../core/util/currency_format.dart';

class MomoTransactionTile extends StatelessWidget {
  final MomoTransaction transaction;
  final VoidCallback? onAction;
  const MomoTransactionTile({
    super.key,
    required this.transaction,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isSend = transaction.type == MomoType.send;
    final isPending = transaction.status == MomoStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line, width: isPending ? 1.5 : 1.0),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isSend ? AppColors.paleSunset : AppColors.paleMint,
            child: Text(
              transaction.initials,
              style: TextStyle(
                color: isSend ? AppColors.sunset : AppColors.forest,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.phone_android_outlined,
                      size: 14,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      transaction.maskedPhone,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isSend
                    ? '-${formatRwf(transaction.amount)}'
                    : '+${formatRwf(transaction.amount)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isSend ? AppColors.sunset : AppColors.forest,
                ),
              ),
              const SizedBox(height: 8),
              if (isPending)
                SizedBox(
                  height: 32,
                  child: FilledButton.tonal(
                    onPressed: onAction,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(
                      isSend ? 'Pay Now' : 'Request',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AppColors.muted,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Done',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

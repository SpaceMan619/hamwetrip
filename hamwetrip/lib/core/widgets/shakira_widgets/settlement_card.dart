import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/util/currency_format.dart';
import '../../../../../data/models/expense.dart';

class SettlementCard extends StatelessWidget {
  final Balance balance;
  final VoidCallback? onSettleUp;

  const SettlementCard({super.key, required this.balance, this.onSettleUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _Person(
                initials: balance.fromInitials,
                name: balance.fromName,
                color: const Color(0xFF059669),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Text(
                      formatRwfCompact(balance.amount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.sunset,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppColors.line,
                    ),
                  ],
                ),
              ),
              _Person(
                initials: balance.toInitials,
                name: balance.toName,
                color: const Color(0xFFD97706),
                alignEnd: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: onSettleUp,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Settle up'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Person extends StatelessWidget {
  const _Person({
    required this.initials,
    required this.name,
    required this.color,
    this.alignEnd = false,
  });

  final String initials;
  final String name;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: alignEnd
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!alignEnd) _avatar(),
          if (!alignEnd) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: alignEnd
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  textAlign: alignEnd ? TextAlign.right : TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const Text(
                  'owes',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          if (alignEnd) const SizedBox(width: 8),
          if (alignEnd) _avatar(),
        ],
      ),
    );
  }

  Widget _avatar() => CircleAvatar(
    radius: 18,
    backgroundColor: color,
    child: Text(
      initials,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/poll.dart';

class ResultOptionBar extends StatelessWidget {
  final PollOption option;
  final int totalVotes;
  final bool isWinner;
  final bool animate;
  const ResultOptionBar({
    super.key,
    required this.option,
    required this.totalVotes,
    this.isWinner = false,
    this.animate = false,
  });

  double get _percentage =>
      totalVotes > 0 ? (option.voteCount / totalVotes) * 100.0 : 0.0;

  @override
  Widget build(BuildContext context) {
    // turn vote counts into a compact result bar.
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWinner ? Colors.white : AppColors.warmSand,
        borderRadius: BorderRadius.circular(14),
        border: isWinner
            ? Border.all(
                color: AppColors.forest.withValues(alpha: 0.3),
                width: 1.5,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (option.emoji != null) ...[
                Text(option.emoji!, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isWinner ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (isWinner)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.forest,
                    size: 20,
                  ),
                ),
              Text(
                '${option.voteCount} votes',
                style: const TextStyle(color: AppColors.muted, fontSize: 14),
              ),
              const SizedBox(width: 8),
              Text(
                '${_percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 18,
                  color: isWinner ? AppColors.forest : AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.line.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      AnimatedContainer(
                        duration: Duration(milliseconds: animate ? 800 : 0),
                        curve: Curves.easeOutCubic,
                        width: animate
                            ? constraints.maxWidth * (_percentage / 100.0)
                            : 0,
                        decoration: BoxDecoration(
                          color: isWinner ? AppColors.forest : AppColors.line,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

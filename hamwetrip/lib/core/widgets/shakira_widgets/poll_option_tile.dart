import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/poll.dart';

class PollOptionTile extends StatelessWidget {
  final PollOption option;
  final int totalVotes;
  final bool isSelected;
  final bool showResults;
  final bool isEnabled;
  final VoidCallback? onTap;

  const PollOptionTile({
    super.key,
    required this.option,
    required this.totalVotes,
    this.isSelected = false,
    this.showResults = false,
    this.isEnabled = true,
    this.onTap,
  });

  double get _percentage =>
      totalVotes > 0 ? (option.voteCount / totalVotes) * 100.0 : 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.forest.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.forest : AppColors.line,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _SelectionIndicator(
                  isSelected: isSelected,
                  showResults: showResults,
                ),
                const SizedBox(width: 12),
                if (option.emoji != null) ...[
                  Text(option.emoji!, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected ? AppColors.forest : AppColors.ink,
                    ),
                  ),
                ),
                if (showResults && isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.forest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Your Vote',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (showResults)
                  Text(
                    '${option.voteCount}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            if (showResults) ...[
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 6,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.line.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            width: constraints.maxWidth * (_percentage / 100.0),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.forest
                                  : AppColors.muted.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_percentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  final bool isSelected;
  final bool showResults;
  const _SelectionIndicator({
    required this.isSelected,
    required this.showResults,
  });

  @override
  Widget build(BuildContext context) {
    if (showResults && !isSelected)
      return const SizedBox(width: 20, height: 20);
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppColors.forest : Colors.transparent,
        border: Border.all(
          color: isSelected ? AppColors.forest : AppColors.line,
          width: 2,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}

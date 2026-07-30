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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SelectionIndicator(
                  isSelected: isSelected,
                  showResults: showResults,
                ),
                const SizedBox(width: 12),

                // NEW: Left-hand Image Placeholder (Instead of emoji)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.sand,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  // The backend will pass a real NetworkImage later.
                  // For now, we use a category icon as a placeholder to keep the layout stable.
                  child: const Icon(
                    Icons.hotel_outlined,
                    size: 26,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected ? AppColors.forest : AppColors.ink,
                        ),
                      ),

                      // NEW: Subtitle text (e.g., "Luxury Suite · Full Board")
                      // Only show when actively voting, not in results view to avoid clutter
                      if (!showResults) ...[
                        const SizedBox(height: 2),
                        const Text(
                          'Category details here', // Backend will inject this text
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
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

            // Progress Bar & Percentage (Unchanged)
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

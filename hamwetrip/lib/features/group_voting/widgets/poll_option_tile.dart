import 'package:flutter/material.dart';
import '../models/poll.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withOpacity(0.45)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withOpacity(0.5),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            // Top row: indicator · emoji · label · badge/count
            Row(
              children: [
                _SelectionIndicator(
                  isSelected: isSelected,
                  showResults: showResults,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 12),
                if (option.emoji != null) ...[
                  Text(option.emoji!, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    option.label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
                if (showResults && isSelected)
                  _VoteBadge(colorScheme: colorScheme)
                else if (showResults)
                  Text(
                    '${option.voteCount}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),

            // Progress bar + percentage
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
                          // Track
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.outlineVariant.withOpacity(
                                0.18,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          // Fill
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            width: constraints.maxWidth * (_percentage / 100.0),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant.withOpacity(
                                      0.45,
                                    ),
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
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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
  final ColorScheme colorScheme;

  const _SelectionIndicator({
    required this.isSelected,
    required this.showResults,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (showResults && !isSelected) {
      return const SizedBox(width: 20, height: 20);
    }
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? colorScheme.primary : Colors.transparent,
        border: Border.all(
          color: isSelected ? colorScheme.primary : colorScheme.outline,
          width: 2,
        ),
      ),
      child: isSelected
          ? Icon(Icons.check, size: 14, color: colorScheme.onPrimary)
          : null,
    );
  }
}

class _VoteBadge extends StatelessWidget {
  final ColorScheme colorScheme;

  const _VoteBadge({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Your Vote',
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

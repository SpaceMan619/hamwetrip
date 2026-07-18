import 'package:flutter/material.dart';
import '../models/poll.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWinner ? colorScheme.surface : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: isWinner
            ? Border.all(
                color: colorScheme.primary.withOpacity(0.3),
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
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: isWinner ? FontWeight.w700 : FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (isWinner)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
              Text(
                '${option.voteCount} votes',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_percentage.toStringAsFixed(0)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isWinner ? colorScheme.primary : colorScheme.onSurface,
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
                          color: colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
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
                          color: isWinner
                              ? colorScheme.primary
                              : colorScheme.outlineVariant.withOpacity(0.8),
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

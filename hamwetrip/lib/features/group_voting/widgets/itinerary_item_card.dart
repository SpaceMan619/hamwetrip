import 'package:flutter/material.dart';
import '../models/itinerary.dart';

class ItineraryItemCard extends StatelessWidget {
  final ItineraryItem item;
  final VoidCallback? onTap;

  const ItineraryItemCard({super.key, required this.item, this.onTap});

  Color _getTypeColor(ColorScheme colorScheme) {
    switch (item.type) {
      case 'transport':
        return colorScheme.tertiary;
      case 'food':
        return Colors.orangeAccent;
      case 'rest':
        return colorScheme.outline;
      default: // activity
        return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final typeColor = _getTypeColor(colorScheme);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Time & Type Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(
                          0.6,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.time,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.type.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: typeColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title & Emoji
                Row(
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: colorScheme.error.withOpacity(0.8),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.location,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Description (if not empty)
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    item.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

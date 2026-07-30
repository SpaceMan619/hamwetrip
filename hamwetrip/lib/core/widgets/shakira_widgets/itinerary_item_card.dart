import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/itinerary.dart';

class ItineraryItemCard extends StatelessWidget {
  final ItineraryItem item;
  final bool isSynced; // Added for the top-right icon
  final VoidCallback? onTap;

  const ItineraryItemCard({
    super.key,
    required this.item,
    this.isSynced = true, // Defaults to synced
    this.onTap,
  });

  Color get _typeColor {
    switch (item.type) {
      case 'transport':
        return AppColors.muted;
      case 'food':
        return Colors.orangeAccent;
      case 'rest':
        return AppColors.line;
      default:
        return AppColors.forest;
    }
  }

  // NEW: Map type to a left-hand icon (Travel Ledger style)
  IconData get _typeIcon {
    switch (item.type) {
      case 'transport':
        return Icons.directions_bus;
      case 'food':
        return Icons.restaurant;
      case 'rest':
        return Icons.hotel;
      default:
        return Icons.hiking; // fallback for 'activity'
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // High-density 12px padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8), // Updated to 0.5rem radius
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // Moved clipBehavior to the outer Container so the Stack icon isn't clipped
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Existing layout
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8), // Updated radius
            // Removed clipBehavior from here
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // UPDATED: Left-hand icon for the category, with time next to it
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.sand,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _typeIcon,
                                size: 14,
                                color: AppColors.forest,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.time, // Now shows the actual time next to the icon
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Keep the text badge on the right
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _typeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.type.toUpperCase(),
                            style: TextStyle(
                              color: _typeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(item.emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.sunset,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.location,
                            style: const TextStyle(
                              color: AppColors.sunset,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        item.description,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // NEW: Clear "Sync Status" icon in the top right corner
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              isSynced
                  ? Icons.cloud_done_outlined
                  : Icons.sync_problem_outlined,
              size: 18,
              color: isSynced ? AppColors.mint : AppColors.sunset,
            ),
          ),
        ],
      ),
    );
  }
}

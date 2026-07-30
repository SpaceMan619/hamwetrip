import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/itinerary.dart';
import '../../../core/widgets/shakira_widgets/itinerary_item_card.dart';

class DetailedItineraryScreen extends StatelessWidget {
  final List<ItineraryDay> days;
  final void Function(ItineraryItem) onEditItem;
  final VoidCallback onAddItem;
  final VoidCallback onEditCalendar;
  final VoidCallback onShare;
  final Widget? bottomNavigation;

  const DetailedItineraryScreen({
    super.key,
    required this.days,
    required this.onEditItem,
    required this.onAddItem,
    required this.onEditCalendar,
    required this.onShare,
    this.bottomNavigation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmSand,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Detailed Itinerary'),
        actions: [
          IconButton(
            onPressed: onEditCalendar,
            icon: const Icon(
              Icons.edit_calendar_outlined,
              color: AppColors.forest,
            ),
          ),
          IconButton(
            onPressed: onShare,
            icon: const Icon(Icons.share_outlined, color: AppColors.forest),
          ),
        ],
      ),
      body: days.isEmpty
          ? const Center(
              child: Text(
                'No itinerary items yet.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: days.length,
              itemBuilder: (context, dayIndex) {
                final day = days[dayIndex];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paleMint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            day.dayTitle,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            day.date,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...day.items.asMap().entries.map((entry) {
                      final isLast = entry.key == day.items.length - 1;
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 40,
                              child: Column(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: AppColors.forest,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                  if (!isLast)
                                    Expanded(
                                      child: Container(
                                        width: 2,
                                        color: AppColors.line,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ItineraryItemCard(
                                item: entry.value,
                                onTap: () => onEditItem(entry.value),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (dayIndex < days.length - 1) const SizedBox(height: 32),
                  ],
                );
              },
            ),
      bottomNavigationBar: bottomNavigation,
      floatingActionButton: FloatingActionButton(
        onPressed: onAddItem,
        backgroundColor: AppColors.forest,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

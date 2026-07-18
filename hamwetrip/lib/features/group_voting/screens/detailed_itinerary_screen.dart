import 'package:flutter/material.dart';
import '../models/itinerary.dart';
import '../widgets/itinerary_item_card.dart';

class DetailedItineraryScreen extends StatefulWidget {
  const DetailedItineraryScreen({super.key});

  @override
  State<DetailedItineraryScreen> createState() =>
      _DetailedItineraryScreenState();
}

class _DetailedItineraryScreenState extends State<DetailedItineraryScreen> {
  // --- Mock Data ---
  final List<ItineraryDay> _days = const [
    ItineraryDay(
      dayTitle: 'Day 1',
      date: 'Friday, Oct 25',
      items: [
        ItineraryItem(
          id: 'i1',
          time: '10:00 AM',
          title: 'Arrive at Kigali International Airport',
          location: 'Kigali International Airport (KGL)',
          description: 'Land, pick up rental van, load group luggage.',
          emoji: '✈️',
          type: 'transport',
        ),
        ItineraryItem(
          id: 'i2',
          time: '12:30 PM',
          title: 'Check-in & Lunch',
          location: 'Heaven Restaurant',
          description: 'Try the local Rwandan buffet.',
          emoji: '🍽️',
          type: 'food',
        ),
        ItineraryItem(
          id: 'i3',
          time: '02:00 PM',
          title: 'Kigali Genocide Memorial',
          location: 'Kigali',
          description:
              'Guided tour of the memorial. Respectful attire required.',
          emoji: '🏛️',
          type: 'activity',
        ),
      ],
    ),
    ItineraryDay(
      dayTitle: 'Day 2',
      date: 'Saturday, Oct 26',
      items: [
        ItineraryItem(
          id: 'i4',
          time: '06:00 AM',
          title: 'Drive to Musanze',
          location: 'Kigali to Musanze (2.5 hrs)',
          description: 'Scenic drive through the hills. Stop for photos.',
          emoji: '🚐',
          type: 'transport',
        ),
        ItineraryItem(
          id: 'i5',
          time: '09:00 AM',
          title: 'Gorilla Trekking Briefing',
          location: 'Kinigi Park Headquarters',
          description: 'Meet guides, split into trekking groups.',
          emoji: '🦍',
          type: 'activity',
        ),
        ItineraryItem(
          id: 'i6',
          time: '04:00 PM',
          title: 'Check into Hotel',
          location: 'Five Volcanoes Boutique Hotel',
          description: 'Relax, showers, and group dinner at the hotel.',
          emoji: '🏨',
          type: 'rest',
        ),
      ],
    ),
    ItineraryDay(
      dayTitle: 'Day 3',
      date: 'Sunday, Oct 27',
      items: [
        ItineraryItem(
          id: 'i7',
          time: '08:00 AM',
          title: 'Lake Kivu Boat Tour',
          location: 'Rubavu (Gisenyi)',
          description: 'Morning boat ride, coffee island visit.',
          emoji: '🚤',
          type: 'activity',
        ),
        ItineraryItem(
          id: 'i8',
          time: '01:00 PM',
          title: 'Drive to Nyungwe',
          location: 'Rubavu to Nyungwe (4 hrs)',
          description: 'Long drive. Grab snacks before leaving.',
          emoji: '🚐',
          type: 'transport',
        ),
      ],
    ),
  ];

  void _handleEditItem(ItineraryItem item) {
    debugPrint('Edit item tapped: ${item.title}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width > 600;
    final horizontalPadding = isTablet ? 48.0 : 20.0;
    final maxWidth = isTablet ? 650.0 : double.infinity;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        title: const Text('Detailed Itinerary'),
        actions: [
          IconButton(
            onPressed: () {}, // Placeholder
            icon: const Icon(Icons.edit_calendar_outlined),
            tooltip: 'Edit Itinerary',
          ),
          IconButton(
            onPressed: () {}, // Placeholder
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Itinerary',
          ),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 24,
        ),
        itemCount: _days.length,
        itemBuilder: (context, dayIndex) {
          final day = _days[dayIndex];
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day Header
                  _DayHeader(day: day, colorScheme: colorScheme, theme: theme),
                  const SizedBox(height: 16),

                  // Timeline Items
                  ...day.items.asMap().entries.map((entry) {
                    final itemIndex = entry.key;
                    final item = entry.value;
                    final isLast = itemIndex == day.items.length - 1;

                    return _TimelineRow(
                      item: item,
                      isLast: isLast,
                      colorScheme: colorScheme,
                      onEdit: () => _handleEditItem(item),
                    );
                  }),

                  // Space between days
                  if (dayIndex < _days.length - 1) const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
      // Floating action to add a new item
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          debugPrint('Add itinerary item tapped');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- Day Header Widget ---
class _DayHeader extends StatelessWidget {
  final ItineraryDay day;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _DayHeader({
    required this.day,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            day.dayTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            day.date,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Timeline Row Widget ---
class _TimelineRow extends StatelessWidget {
  final ItineraryItem item;
  final bool isLast;
  final ColorScheme colorScheme;
  final VoidCallback onEdit;

  const _TimelineRow({
    required this.item,
    required this.isLast,
    required this.colorScheme,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Track (Line & Dot)
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Dot
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 3),
                  ),
                ),
                // Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Content Card
          Expanded(
            child: ItineraryItemCard(item: item, onTap: onEdit),
          ),
        ],
      ),
    );
  }
}

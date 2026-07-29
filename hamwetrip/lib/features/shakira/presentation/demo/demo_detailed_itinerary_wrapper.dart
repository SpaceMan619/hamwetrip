import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../detailed_itinerary_screen.dart';
import 'controllers/demo_itinerary_controller.dart';
import '../../../../../core/widgets/hamwe_bottom_navigation.dart';

/// Wires up mock itinerary data to your pure UI screen.
class DemoDetailedItineraryWrapper extends StatefulWidget {
  const DemoDetailedItineraryWrapper({super.key});

  @override
  State<DemoDetailedItineraryWrapper> createState() =>
      _DemoDetailedItineraryWrapperState();
}

class _DemoDetailedItineraryWrapperState
    extends State<DemoDetailedItineraryWrapper> {
  late final DemoItineraryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DemoItineraryController();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetailedItineraryScreen(
      days: _controller.days,
      bottomNavigation: const HamweBottomNavigation(
        selected: HamweDestination.trips,
      ),

      // Fixes "Empty Handler" - Tapping an item on the timeline
      onEditItem: (item) {
        // Toggle the completion state locally
        _controller.toggleItemCompletion(item.id);

        final isNowCompleted = _controller.isItemCompleted(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNowCompleted
                  ? '${item.emoji} ${item.title} marked as done!'
                  : '${item.emoji} ${item.title} marked as pending.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: isNowCompleted
                ? AppColors.forest
                : AppColors.muted,
          ),
        );
      },

      // Fixes "Empty Handler" - FAB Add button
      onAddItem: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Add itinerary item will be available after backend integration',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },

      // Fixes "Empty Handler" - Edit Calendar button
      onEditCalendar: () {
        _controller.clearSearch(); // Example of doing local state work
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Edit calendar mode (Demo only)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },

      // Fixes "Empty Handler" - Share button
      onShare: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Itinerary link copied to clipboard! (Simulated)'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.forest,
          ),
        );
      },
    );
  }
}

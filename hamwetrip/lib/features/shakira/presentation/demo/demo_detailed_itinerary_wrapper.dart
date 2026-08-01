import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/repository_providers.dart';
import '../detailed_itinerary_screen.dart';
import 'controllers/demo_itinerary_controller.dart';
import '../../../../core/widgets/hamwe_bottom_navigation.dart';
import '../../../../core/widgets/create_forms.dart';
import '../../../../core/widgets/trip_scoped.dart';

/// Wires up itinerary data from Firestore to the pure UI screen.
class DemoDetailedItineraryWrapper extends StatelessWidget {
  const DemoDetailedItineraryWrapper({super.key});

  @override
  Widget build(BuildContext context) => TripScoped(
    builder: (tripId) =>
        _DetailedItineraryView(key: ValueKey(tripId), tripId: tripId),
  );
}

class _DetailedItineraryView extends ConsumerStatefulWidget {
  const _DetailedItineraryView({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<_DetailedItineraryView> createState() =>
      _DemoDetailedItineraryWrapperState();
}

class _DemoDetailedItineraryWrapperState
    extends ConsumerState<_DetailedItineraryView> {
  late final DemoItineraryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DemoItineraryController(
      repository: ref.read(itineraryRepositoryProvider),
      tripId: widget.tripId,
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final days = _controller.days
        .where((day) => day.id.isNotEmpty)
        .map((day) => (id: day.id, label: day.dayTitle))
        .toList(growable: false);

    if (days.isEmpty) {
      // An activity is appended to a day, so there is nothing to add it to yet.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This trip has no itinerary days yet.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final input = await showAddItineraryItemForm(context, days);
    if (input == null || !mounted) return;

    final created = await _controller.createItem(
      dayId: input.dayId,
      time: input.time,
      title: input.title,
      location: input.location,
      description: input.description,
      emoji: input.emoji,
      type: input.type,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          created
              ? 'Added to the itinerary'
              : _controller.error?.message ?? 'Could not add that',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: created ? AppColors.forest : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_controller.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.warmSand,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Error state
    if (_controller.hasError) {
      return Scaffold(
        backgroundColor: AppColors.warmSand,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _controller.error?.message ?? 'Something went wrong',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _controller.retry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return DetailedItineraryScreen(
      days: _controller.days,
      bottomNavigation: const HamweBottomNavigation(
        selected: HamweDestination.trips,
      ),
      onEditItem: (item) async {
        await _controller.toggleItemCompletion(item.id);

        if (!context.mounted) return;
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
      onAddItem: _addItem,
      onEditCalendar: () {
        _controller.clearSearch();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Edit calendar mode'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onShare: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Itinerary link copied to clipboard!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.forest,
          ),
        );
      },
    );
  }
}

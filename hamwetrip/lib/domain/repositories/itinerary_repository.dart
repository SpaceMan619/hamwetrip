import '../../data/models/itinerary.dart';

/// Itinerary days and items for the detailed itinerary screen.
abstract interface class ItineraryRepository {
  /// All itinerary days for a trip, live-updated.
  Stream<List<ItineraryDay>> watchItinerary(String tripId);

  /// Toggles the completion state of an itinerary item.
  Future<void> toggleItemCompletion({
    required String tripId,
    required String itemId,
  });

  /// Creates a new itinerary item under a day.
  Future<ItineraryItem> createItem({
    required String tripId,
    required String dayId,
    required ItineraryItem item,
  });
}

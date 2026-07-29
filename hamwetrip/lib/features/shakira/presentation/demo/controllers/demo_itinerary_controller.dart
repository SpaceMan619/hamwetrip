import 'package:flutter/foundation.dart';
import '../../../../../data/models/itinerary.dart';
import '../../../../../features/shakira/data/demo/mock_itinerary.dart';

class DemoItineraryController extends ChangeNotifier {
  final List<ItineraryDay> _allDays = List.from(mockItinerary);

  // Tracks completion state since ItineraryItem doesn't have an isCompleted field
  final Set<String> _completedItemIds = {};
  String? _searchQuery;

  List<ItineraryDay> get days => _filteredDays;
  int get totalItems => _allDays.fold(0, (sum, d) => sum + d.items.length);
  int get completedItems => _completedItemIds.length;

  List<ItineraryDay> get _filteredDays {
    if (_searchQuery == null || _searchQuery!.isEmpty) return _allDays;

    final q = _searchQuery!.toLowerCase();
    return _allDays
        .map((day) {
          // Filter items within the day that match the search query
          final filteredItems = day.items
              .where(
                (item) =>
                    item.title.toLowerCase().contains(q) ||
                    item.location.toLowerCase().contains(q) ||
                    item.description.toLowerCase().contains(q),
              )
              .toList();

          // Only return the day if it has matching items
          if (filteredItems.isEmpty) return null;
          return ItineraryDay(
            dayTitle: day.dayTitle,
            date: day.date,
            items: filteredItems,
          );
        })
        .whereType<ItineraryDay>()
        .toList();
  }

  bool isItemCompleted(String itemId) => _completedItemIds.contains(itemId);

  // ──────────────────────────────────────────────
  // Actions
  // ──────────────────────────────────────────────

  void toggleItemCompletion(String itemId) {
    if (_completedItemIds.contains(itemId)) {
      _completedItemIds.remove(itemId);
    } else {
      _completedItemIds.add(itemId);
    }
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = null;
    notifyListeners();
  }
}

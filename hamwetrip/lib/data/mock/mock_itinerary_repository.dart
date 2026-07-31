import 'dart:async';

import '../../data/models/itinerary.dart';
import '../../domain/repositories/itinerary_repository.dart';
import '../../features/shakira/data/demo/mock_itinerary.dart';

/// In-memory [ItineraryRepository] backed by the existing mock data.
class MockItineraryRepository implements ItineraryRepository {
  List<ItineraryDay> _days = List.from(mockItinerary);
  final Set<String> _completedItemIds = {};
  final _controllers = <StreamController<List<ItineraryDay>>>[];

  @override
  Stream<List<ItineraryDay>> watchItinerary(String tripId) {
    final controller = StreamController<List<ItineraryDay>>();
    _controllers.add(controller);
    controller.add(List.from(_days));
    return controller.stream;
  }

  void _notify() {
    for (final c in _controllers) {
      if (!c.isClosed) c.add(List.from(_days));
    }
  }

  @override
  Future<void> toggleItemCompletion({
    required String tripId,
    required String itemId,
  }) async {
    if (_completedItemIds.contains(itemId)) {
      _completedItemIds.remove(itemId);
    } else {
      _completedItemIds.add(itemId);
    }
    _notify();
  }

  @override
  Future<ItineraryItem> createItem({
    required String tripId,
    required String dayId,
    required ItineraryItem item,
  }) async {
    final newId = 'item_${DateTime.now().millisecondsSinceEpoch}';
    final newItem = ItineraryItem(
      id: newId,
      time: item.time,
      title: item.title,
      location: item.location,
      description: item.description,
      emoji: item.emoji,
      type: item.type,
    );
    _days = _days.map((day) {
      if (day.dayTitle != dayId) return day;
      return ItineraryDay(
        dayTitle: day.dayTitle,
        date: day.date,
        items: [...day.items, newItem],
      );
    }).toList();
    _notify();
    return newItem;
  }

  bool isItemCompleted(String itemId) => _completedItemIds.contains(itemId);

  void dispose() {
    for (final c in _controllers) {
      if (!c.isClosed) c.close();
    }
  }
}

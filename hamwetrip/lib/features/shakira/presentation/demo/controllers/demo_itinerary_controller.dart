import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../../../core/error/app_error.dart';
import '../../../../../data/models/itinerary.dart';
import '../../../../../domain/repositories/itinerary_repository.dart';

class DemoItineraryController extends ChangeNotifier {
  final ItineraryRepository _repository;
  final String tripId;

  List<ItineraryDay> _days = [];
  final Set<String> _completedItemIds = {};
  bool _isLoading = true;
  AppError? _error;
  StreamSubscription<List<ItineraryDay>>? _subscription;

  DemoItineraryController({
    required ItineraryRepository repository,
    this.tripId = 'demo-trip',
  }) : _repository = repository {
    _loadItinerary();
  }

  bool get isLoading => _isLoading;
  AppError? get error => _error;
  bool get hasError => _error != null;

  List<ItineraryDay> get days => _days;

  bool isItemCompleted(String itemId) => _completedItemIds.contains(itemId);

  void _loadItinerary() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _subscription = _repository
        .watchItinerary(tripId)
        .listen(
          (days) {
            _days = days;
            _isLoading = false;
            notifyListeners();
          },
          onError: (Object error) {
            _isLoading = false;
            _error = error is AppError
                ? error
                : const UnknownError(message: 'Failed to load itinerary.');
            notifyListeners();
          },
        );
  }

  Future<void> retry() async {
    await _subscription?.cancel();
    _loadItinerary();
  }

  /// Adds an activity to [dayId], letting the watch stream bring it back.
  ///
  /// A day has to exist first: the repository appends to that day's `items`
  /// array rather than creating a document of its own, which is why the form
  /// asks which day rather than offering a free date.
  Future<bool> createItem({
    required String dayId,
    required String time,
    required String title,
    required String location,
    required String description,
    required String emoji,
    required String type,
  }) async {
    try {
      await _repository.createItem(
        tripId: tripId,
        dayId: dayId,
        item: ItineraryItem(
          // Replaced by the repository, which mints the stored id.
          id: '',
          time: time.trim(),
          title: title.trim(),
          location: location.trim(),
          description: description.trim(),
          emoji: emoji,
          type: type,
        ),
      );
      return true;
    } on AppError catch (e) {
      _error = e;
      notifyListeners();
      return false;
    } catch (e) {
      _error = UnknownError(cause: e);
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleItemCompletion(String itemId) async {
    try {
      if (_completedItemIds.contains(itemId)) {
        _completedItemIds.remove(itemId);
      } else {
        _completedItemIds.add(itemId);
      }
      notifyListeners();
      await _repository.toggleItemCompletion(tripId: tripId, itemId: itemId);
    } on AppError catch (e) {
      _error = e;
      notifyListeners();
    } catch (e) {
      _error = UnknownError(cause: e);
      notifyListeners();
    }
  }

  void clearSearch() {
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

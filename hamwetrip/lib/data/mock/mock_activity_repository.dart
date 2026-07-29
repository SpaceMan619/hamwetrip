import '../../domain/models/activity_event.dart';
import '../../domain/repositories/activity_repository.dart';
import 'mock_backend.dart';

/// In-memory [ActivityRepository].
class MockActivityRepository implements ActivityRepository {
  MockActivityRepository(this._backend);

  final MockBackend _backend;

  /// Newest first. Pending events (null [ActivityEvent.createdAt]) sort to the
  /// top, because a write the user just made should appear immediately rather
  /// than surface at the bottom once the server acknowledges it.
  int _byRecency(ActivityEvent a, ActivityEvent b) {
    final left = a.createdAt;
    final right = b.createdAt;
    if (left == null && right == null) return 0;
    if (left == null) return -1;
    if (right == null) return 1;
    return right.compareTo(left);
  }

  @override
  Stream<List<ActivityEvent>> watchActivity(String tripId, {int limit = 30}) {
    return _backend.watch('watchActivity', () {
      final uid = _backend.signedInUid;
      // Non-members see nothing, mirroring what the security rule will enforce.
      if (uid == null || _backend.memberOf(tripId, uid) == null) {
        return const <ActivityEvent>[];
      }
      final events = <ActivityEvent>[...?_backend.activity[tripId]]
        ..sort(_byRecency);
      return events.take(limit).toList(growable: false);
    });
  }

  @override
  Stream<List<ActivityEvent>> watchMyActivity({int limit = 30}) {
    return _backend.watch('watchMyActivity', () {
      final uid = _backend.signedInUid;
      if (uid == null) return const <ActivityEvent>[];

      final events = <ActivityEvent>[];
      for (final entry in _backend.activity.entries) {
        if (_backend.memberOf(entry.key, uid) == null) continue;
        events.addAll(entry.value);
      }
      events.sort(_byRecency);
      return events.take(limit).toList(growable: false);
    });
  }

  @override
  Future<void> recordEvent(ActivityEvent event) async {
    await _backend.guard('recordEvent');
    _backend.activity
        .putIfAbsent(event.tripId, () => <ActivityEvent>[])
        .add(event);
    _backend.emitChange();
  }
}

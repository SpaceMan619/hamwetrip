import '../models/activity_event.dart';

/// The trip audit trail.
///
/// Consumed by the home feed (across all trips) and the per-trip activity
/// screen.
abstract interface class ActivityRepository {
  /// Events for one trip, newest first.
  ///
  /// Pagination is expressed as a growing [limit] rather than a cursor, because
  /// a cursor cannot stay live: a paged cursor query stops reflecting new
  /// events at the head of the list. The controller raises [limit] to load more
  /// and re-subscribes, so the newest events keep arriving while older ones are
  /// revealed.
  ///
  /// Costs one extra read per already-loaded event on each page, which is
  /// acceptable at trip scale. Revisit if a trip ever exceeds a few hundred
  /// events.
  Stream<List<ActivityEvent>> watchActivity(String tripId, {int limit});

  /// Events across every trip the signed-in user belongs to, newest first.
  ///
  /// This is what the home feed renders. Needs a collection-group index on
  /// `activity` ordered by `createdAt`, and a rule that permits collection
  /// group reads only for events whose trip the caller is a member of.
  Stream<List<ActivityEvent>> watchMyActivity({int limit});

  /// Appends an event.
  ///
  /// Present because the guide lists it, and used by the mocks and during the
  /// transition. **Once the Cloud Function triggers land (P3-17), the activity
  /// path becomes client-read-only and the Firebase implementation of this
  /// method will start throwing [PermissionDeniedError].** Do not build a
  /// feature that depends on writing activity from a client.
  Future<void> recordEvent(ActivityEvent event);
}

import '../models/invite.dart';
import '../models/trip.dart';
import '../models/trip_member.dart';

/// Trips, membership and invitations.
///
/// Consumed by the home feed, trip dashboard, create-trip and invite screens.
abstract interface class TripRepository {
  /// Trips the signed-in user belongs to, newest first.
  ///
  /// Answered by `collectionGroup('members').where('uid', isEqualTo: me)`
  /// followed by a load of each matching trip. The trip document holds no
  /// membership data, so there is no single-query shortcut and no denormalized
  /// array that can fall out of sync.
  ///
  /// Emits the current list immediately (from cache when offline), then live
  /// updates. Emits an empty list — not an error — when the user has no trips,
  /// so the home feed can show its empty state.
  Stream<List<Trip>> watchMyTrips();

  /// A single trip.
  ///
  /// Emits null if the trip is deleted, or if the user is removed from it while
  /// the screen is open. The dashboard must treat that as "you no longer have
  /// access" and navigate away, rather than as a load failure.
  Stream<Trip?> watchTrip(String tripId);

  /// Creates a trip and makes the caller its organizer.
  ///
  /// The trip document, the organizer's member document and the `trip_created`
  /// activity event must all be written atomically. A trip that exists with no
  /// members is unreachable by anyone, including its creator.
  ///
  /// [requestId] makes the call idempotent: repeating it with the same id
  /// returns the existing trip instead of creating a second one. Generate it
  /// once when the form opens, not on each tap.
  Future<Trip> createTrip({
    required String name,
    required String destination,
    required String requestId,
    DateTime? startDate,
    DateTime? endDate,
    String currency,
  });

  /// Organizer-only. Omitted parameters are left untouched.
  Future<Trip> updateTrip({
    required String tripId,
    String? name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    TripStatus? status,
  });

  /// Members of a trip. Emits immediately, then live.
  Stream<List<TripMember>> watchMembers(String tripId);

  /// The signed-in user's own membership, which is what every permission check
  /// in the UI reads to decide whether to show organizer-only controls.
  ///
  /// Emits null once the user is no longer a member.
  Stream<TripMember?> watchMyMembership(String tripId);

  /// Organizer-only. Generates a fresh code.
  ///
  /// [maxUses] defaults to [Invite.unlimitedUses]. A null [expiresAt] means the
  /// code never expires.
  Future<Invite> createInvite({
    required String tripId,
    int maxUses,
    DateTime? expiresAt,
  });

  /// Active invites for a trip, so the invite screen can show and revoke them.
  Stream<List<Invite>> watchInvites(String tripId);

  /// Organizer-only. Kills a leaked code without waiting for expiry.
  Future<void> revokeInvite({required String tripId, required String code});

  /// Redeems a code and joins the caller to the trip.
  ///
  /// The code is looked up in the global `invites` collection, since the caller
  /// does not yet know the trip id — see [Invite] for why that collection is
  /// not nested under the trip.
  ///
  /// Validation of expiry, revocation, remaining uses and existing membership
  /// happens inside a single transaction that also increments `usedCount`, so
  /// two people redeeming a single-use code cannot both succeed.
  ///
  /// Throws [NotFoundError] for an unknown code, [InvalidInputError] for an
  /// expired, revoked or exhausted one, and [AlreadyExistsError] when the
  /// caller is already a member. Returns the joined trip.
  Future<Trip> joinTrip({required String code});

  /// Organizer-only. Removes someone else from the trip.
  ///
  /// Deleting the member document is the whole operation — membership lives in
  /// exactly one place.
  Future<void> removeMember({required String tripId, required String uid});

  /// The caller removes themselves.
  ///
  /// Throws [InvalidInputError] if they are the last organizer — a trip with no
  /// organizer can never be administered again, so this is refused rather than
  /// silently orphaning the trip.
  Future<void> leaveTrip(String tripId);

  /// Organizer-only. Promotes or demotes a member.
  Future<void> updateMemberRole({
    required String tripId,
    required String uid,
    required TripRole role,
  });
}

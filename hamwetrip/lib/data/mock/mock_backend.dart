import 'dart:async';

import '../../core/error/app_error.dart';
import '../../domain/models/activity_event.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/invite.dart';
import '../../domain/models/trip.dart';
import '../../domain/models/trip_member.dart';

/// In-memory stand-in for Firebase, shared by every mock repository.
///
/// Exists so frontend work never waits on backend work, and so the four UI
/// states (loading, data, empty, error) can be exercised deliberately instead of
/// only when the network happens to misbehave.
///
/// The mocks enforce the same rules as the real implementations — last
/// organizer cannot leave, an exhausted invite is refused, a duplicate join is
/// rejected. A mock that always succeeds would let the UI ship without any
/// error handling at all, which is the failure mode this whole layer exists to
/// prevent.
class MockBackend {
  MockBackend({this.latency = const Duration(milliseconds: 350)});

  /// Simulated round-trip delay. Set to [Duration.zero] in widget tests, and
  /// raise it to rehearse slow-network behaviour.
  Duration latency;

  /// Fails the next matching call. The key is the operation name passed to
  /// [guard], for example `'createTrip'`. Set `'*'` to fail everything.
  ///
  /// The error is consumed on use unless [persistentFailures] contains the key.
  final Map<String, AppError> failures = <String, AppError>{};

  /// Operations in [failures] that should keep failing rather than clearing
  /// after one throw — useful for rehearsing a retry button.
  final Set<String> persistentFailures = <String>{};

  /// uid of the signed-in user, or null when signed out.
  String? signedInUid;

  final Map<String, AppUser> users = <String, AppUser>{};

  /// uid -> password. Mock-only; real auth never sees a password.
  final Map<String, String> passwords = <String, String>{};

  final Map<String, Trip> trips = <String, Trip>{};

  /// tripId -> uid -> member.
  final Map<String, Map<String, TripMember>> members =
      <String, Map<String, TripMember>>{};

  /// Global, keyed by code — mirroring the real top-level `invites` collection.
  final Map<String, Invite> invites = <String, Invite>{};

  /// tripId -> events, newest last. Reversed on read.
  final Map<String, List<ActivityEvent>> activity =
      <String, List<ActivityEvent>>{};

  /// requestId -> tripId, backing idempotent creates.
  final Map<String, String> createTripRequests = <String, String>{};

  final StreamController<void> _changes = StreamController<void>.broadcast();

  var _idCounter = 0;

  /// Monotonic id generator, so seeded and runtime ids never collide.
  String nextId(String prefix) => '${prefix}_${++_idCounter}';

  /// Notifies every open stream that state changed.
  void emitChange() {
    if (!_changes.isClosed) _changes.add(null);
  }

  /// Builds a stream matching the contract: current value first, then a fresh
  /// value on every subsequent change.
  ///
  /// [latency] is applied before the first emission so subscribers genuinely
  /// pass through a loading state — without it the data arrives synchronously
  /// and a loading spinner that is broken in production never shows up as
  /// broken against the mocks.
  ///
  /// Injected failures for [operation] surface as a stream error, which is how
  /// a real permission change mid-subscription would arrive.
  Stream<T> watch<T>(String operation, T Function() read) async* {
    if (latency > Duration.zero) await Future<void>.delayed(latency);

    final error = failures[operation] ?? failures['*'];
    if (error != null) {
      if (!persistentFailures.contains(operation) &&
          !persistentFailures.contains('*')) {
        failures.remove(operation);
      }
      throw error;
    }

    yield read();
    yield* _changes.stream.map((_) => read());
  }

  /// Applies latency and any injected failure for [operation].
  ///
  /// Every mock command and query calls this first, so a test can make any
  /// single operation fail without touching the repository under test.
  Future<void> guard(String operation) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);

    final error = failures[operation] ?? failures['*'];
    if (error != null) {
      if (!persistentFailures.contains(operation) &&
          !persistentFailures.contains('*')) {
        failures.remove(operation);
      }
      throw error;
    }
  }

  /// The signed-in user, or throws when signed out. Commands that require a
  /// session call this rather than assuming one exists.
  String requireUid() {
    final uid = signedInUid;
    if (uid == null) {
      throw const AuthError(message: 'You need to be signed in to do that.');
    }
    return uid;
  }

  TripMember? memberOf(String tripId, String uid) => members[tripId]?[uid];

  /// Throws unless [uid] is a member of [tripId].
  TripMember requireMember(String tripId, String uid) {
    final member = memberOf(tripId, uid);
    if (member == null) {
      throw const PermissionDeniedError(
        message: "You're not a member of this trip.",
      );
    }
    return member;
  }

  /// Throws unless [uid] is an organizer of [tripId].
  TripMember requireOrganizer(String tripId, String uid) {
    final member = requireMember(tripId, uid);
    if (!member.role.canManageMembership) {
      throw const PermissionDeniedError(
        message: 'Only a trip organizer can do that.',
      );
    }
    return member;
  }

  /// Appends an activity event.
  ///
  /// [createdAt] is injectable because seeded events written in a loop would
  /// otherwise all share a single timestamp, leaving the feed's "newest first"
  /// ordering undefined — `List.sort` is not stable, so equal keys come back in
  /// arbitrary order and the demo feed reshuffles between runs.
  void addActivity({
    required String tripId,
    required ActivityType type,
    required String actorId,
    required String summary,
    String? entityId,
    DateTime? createdAt,
  }) {
    activity
        .putIfAbsent(tripId, () => <ActivityEvent>[])
        .add(
          ActivityEvent(
            id: nextId('act'),
            tripId: tripId,
            type: type,
            actorId: actorId,
            actorName: users[actorId]?.displayName,
            summary: summary,
            entityId: entityId,
            createdAt: (createdAt ?? DateTime.now()).toUtc(),
          ),
        );
  }

  /// Writes a membership.
  ///
  /// The member document is the single source of truth — nothing is
  /// denormalized onto the trip, so there is nothing here that can drift.
  void putMember(TripMember member) {
    members.putIfAbsent(
      member.tripId,
      () => <String, TripMember>{},
    )[member.uid] = member;
  }

  /// Removes a membership.
  void dropMember(String tripId, String uid) {
    members[tripId]?.remove(uid);
  }

  /// Trip ids [uid] belongs to.
  ///
  /// Stands in for `collectionGroup('members').where('uid', isEqualTo: uid)`,
  /// which is how the Firebase implementation answers the same question.
  Iterable<String> tripIdsFor(String uid) {
    return members.entries
        .where((entry) => entry.value.containsKey(uid))
        .map((entry) => entry.key);
  }

  void dispose() {
    _changes.close();
  }

  /// Builds the shared fixture set the delivery guide asks for: an organizer,
  /// two members, one pending invite, and one removed member.
  ///
  /// The trip deliberately matches the hardcoded `TripSummary.demo` the screens
  /// already render, so swapping a screen onto a mock repository does not
  /// change what appears on the device.
  factory MockBackend.seeded({
    Duration latency = const Duration(milliseconds: 350),
    bool signedIn = true,
  }) {
    final backend = MockBackend(latency: latency);
    final now = DateTime.now().toUtc();

    const organizerId = 'u_aline';
    const memberOneId = 'u_eric';
    const memberTwoId = 'u_chantal';
    const removedId = 'u_jean';
    const tripId = 't_nyungwe';

    void addUser(String uid, String name, String email, {String? phone}) {
      backend.users[uid] = AppUser(
        uid: uid,
        displayName: name,
        email: email,
        phone: phone,
        createdAt: now.subtract(const Duration(days: 60)),
      );
      backend.passwords[uid] = 'hamwe1234';
    }

    addUser(
      organizerId,
      'Aline Uwase',
      'aline@example.com',
      phone: '0788123456',
    );
    addUser(
      memberOneId,
      'Eric Habimana',
      'eric@example.com',
      phone: '0788234567',
    );
    addUser(memberTwoId, 'Chantal Mukamana', 'chantal@example.com');
    addUser(removedId, 'Jean Bosco', 'jean@example.com');

    backend.trips[tripId] = Trip(
      id: tripId,
      name: 'Nyungwe National Park',
      destination: 'Rwanda',
      ownerId: organizerId,
      currency: 'RWF',
      status: TripStatus.planning,
      startDate: DateTime.utc(now.year, 10, 12),
      endDate: DateTime.utc(now.year, 10, 18),
      createdAt: now.subtract(const Duration(days: 14)),
      updatedAt: now.subtract(const Duration(days: 2)),
    );

    void join(String uid, TripRole role, int daysAgo, {String? withCode}) {
      backend.putMember(
        TripMember(
          uid: uid,
          tripId: tripId,
          role: role,
          displayName: backend.users[uid]!.displayName,
          joinedAt: now.subtract(Duration(days: daysAgo)),
          joinedWithCode: withCode,
        ),
      );
    }

    // The organizer created the trip, so redeemed no code.
    join(organizerId, TripRole.organizer, 14);
    join(memberOneId, TripRole.member, 12, withCode: 'HAMWE7');
    join(memberTwoId, TripRole.member, 9, withCode: 'HAMWE7');

    // The removed member: joined, then was removed. Absent from `members`, but
    // still present in the audit trail — which is exactly the state the
    // activity feed and the security rules need to handle.
    backend.addActivity(
      tripId: tripId,
      type: ActivityType.tripCreated,
      actorId: organizerId,
      summary: 'Aline created the trip',
      entityId: tripId,
      createdAt: now.subtract(const Duration(days: 14)),
    );
    backend.addActivity(
      tripId: tripId,
      type: ActivityType.memberJoined,
      actorId: memberOneId,
      summary: 'Eric joined the trip',
      entityId: memberOneId,
      createdAt: now.subtract(const Duration(days: 12)),
    );
    backend.addActivity(
      tripId: tripId,
      type: ActivityType.memberJoined,
      actorId: memberTwoId,
      summary: 'Chantal joined the trip',
      entityId: memberTwoId,
      createdAt: now.subtract(const Duration(days: 9)),
    );
    backend.addActivity(
      tripId: tripId,
      type: ActivityType.memberRemoved,
      actorId: organizerId,
      summary: 'Aline removed Jean Bosco from the trip',
      entityId: removedId,
      createdAt: now.subtract(const Duration(days: 5)),
    );

    backend.invites['HAMWE7'] = Invite(
      code: 'HAMWE7',
      tripId: tripId,
      createdBy: organizerId,
      maxUses: 5,
      usedCount: 2,
      revoked: false,
      createdAt: now.subtract(const Duration(days: 13)),
      expiresAt: now.add(const Duration(days: 20)),
    );

    if (signedIn) backend.signedInUid = organizerId;
    return backend;
  }
}

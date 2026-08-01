import '../../core/error/app_error.dart';
import '../../domain/models/activity_event.dart';
import '../../domain/models/invite.dart';
import '../../domain/models/trip.dart';
import '../../domain/models/trip_member.dart';
import '../../domain/repositories/trip_repository.dart';
import 'mock_backend.dart';

/// In-memory [TripRepository].
///
/// Enforces the same invariants as the Firebase implementation will: atomic
/// create, membership consistency, single-use invite accounting, and the
/// last-organizer rule.
class MockTripRepository implements TripRepository {
  MockTripRepository(this._backend);

  final MockBackend _backend;

  /// Newest first, with undated trips last rather than crashing the sort.
  int _byRecency(Trip a, Trip b) {
    final left = a.createdAt;
    final right = b.createdAt;
    if (left == null && right == null) return a.name.compareTo(b.name);
    if (left == null) return 1;
    if (right == null) return -1;
    return right.compareTo(left);
  }

  @override
  Stream<List<Trip>> watchMyTrips() {
    return _backend.watch('watchMyTrips', () {
      final uid = _backend.signedInUid;
      if (uid == null) return const <Trip>[];

      // Mirrors the Firebase implementation: find the caller's member
      // documents via a collection-group query, then load those trips. The
      // trip document itself carries no membership information.
      return _backend
          .tripIdsFor(uid)
          .map((tripId) => _backend.trips[tripId])
          .whereType<Trip>()
          // Mirrors the Firebase implementation: archiving is how a trip is
          // "deleted" — see FirebaseTripRepository._loadTripsFor.
          .where((trip) => trip.status != TripStatus.archived)
          .toList()
        ..sort(_byRecency);
    });
  }

  @override
  Stream<Trip?> watchTrip(String tripId) {
    return _backend.watch('watchTrip', () {
      final uid = _backend.signedInUid;
      final trip = _backend.trips[tripId];
      // Emitting null rather than throwing once access is lost: the dashboard
      // treats that as "you were removed" and leaves, which is the documented
      // behaviour and is indistinguishable from deletion to the client.
      if (trip == null ||
          uid == null ||
          _backend.memberOf(tripId, uid) == null) {
        return null;
      }
      return trip;
    });
  }

  @override
  Future<Trip> createTrip({
    required String name,
    required String destination,
    required String requestId,
    DateTime? startDate,
    DateTime? endDate,
    String currency = 'RWF',
  }) async {
    await _backend.guard('createTrip');
    final uid = _backend.requireUid();

    // Idempotency: a second tap with the same requestId returns the trip the
    // first tap created instead of making a duplicate.
    final existingId = _backend.createTripRequests[requestId];
    if (existingId != null) {
      final existing = _backend.trips[existingId];
      if (existing != null) return existing;
    }

    if (name.trim().isEmpty) {
      throw const InvalidInputError(message: 'Give your trip a name.');
    }
    if (destination.trim().isEmpty) {
      throw const InvalidInputError(message: 'Where are you going?');
    }
    if (startDate != null && endDate != null && endDate.isBefore(startDate)) {
      throw const InvalidInputError(
        message: 'The end date cannot be before the start date.',
      );
    }

    final now = DateTime.now().toUtc();
    final tripId = _backend.nextId('t');
    final creator = _backend.users[uid];

    // Trip, organizer membership and the activity event all land together —
    // the real implementation must use a single batch, because a trip with no
    // members is unreachable by anyone including its creator.
    _backend.trips[tripId] = Trip(
      id: tripId,
      name: name.trim(),
      destination: destination.trim(),
      ownerId: uid,
      currency: currency,
      status: TripStatus.planning,
      startDate: startDate?.toUtc(),
      endDate: endDate?.toUtc(),
      createdAt: now,
      updatedAt: now,
    );
    _backend.putMember(
      TripMember(
        uid: uid,
        tripId: tripId,
        role: TripRole.organizer,
        displayName: creator?.displayName ?? 'Organizer',
        photoUrl: creator?.photoUrl,
        joinedAt: now,
      ),
    );
    _backend.addActivity(
      tripId: tripId,
      type: ActivityType.tripCreated,
      actorId: uid,
      summary: '${creator?.displayName ?? 'Someone'} created the trip',
      entityId: tripId,
    );

    _backend.createTripRequests[requestId] = tripId;
    _backend.emitChange();
    return _backend.trips[tripId]!;
  }

  @override
  Future<Trip> updateTrip({
    required String tripId,
    String? name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    TripStatus? status,
  }) async {
    await _backend.guard('updateTrip');
    final uid = _backend.requireUid();
    _backend.requireOrganizer(tripId, uid);

    final trip = _backend.trips[tripId];
    if (trip == null) throw const NotFoundError();

    if (name != null && name.trim().isEmpty) {
      throw const InvalidInputError(message: 'Give your trip a name.');
    }

    final updated = trip.copyWith(
      name: name?.trim(),
      destination: destination?.trim(),
      startDate: startDate?.toUtc(),
      endDate: endDate?.toUtc(),
      status: status,
      updatedAt: DateTime.now().toUtc(),
    );
    _backend.trips[tripId] = updated;
    _backend.emitChange();
    return updated;
  }

  @override
  Stream<List<TripMember>> watchMembers(String tripId) {
    return _backend.watch('watchMembers', () {
      final roster = _backend.members[tripId];
      if (roster == null) return const <TripMember>[];
      return roster.values.toList()..sort((a, b) {
        // Organizers first, then alphabetical — a stable order so the list
        // does not reshuffle on every live update.
        if (a.role != b.role) {
          if (a.role == TripRole.organizer) return -1;
          if (b.role == TripRole.organizer) return 1;
        }
        return a.displayName.compareTo(b.displayName);
      });
    });
  }

  @override
  Stream<TripMember?> watchMyMembership(String tripId) {
    return _backend.watch('watchMyMembership', () {
      final uid = _backend.signedInUid;
      if (uid == null) return null;
      return _backend.memberOf(tripId, uid);
    });
  }

  @override
  Future<Invite> createInvite({
    required String tripId,
    int maxUses = Invite.unlimitedUses,
    DateTime? expiresAt,
  }) async {
    await _backend.guard('createInvite');
    final uid = _backend.requireUid();
    _backend.requireOrganizer(tripId, uid);

    if (maxUses != Invite.unlimitedUses && maxUses < 1) {
      throw const InvalidInputError(
        message: 'An invite has to allow at least one person.',
      );
    }

    // Retry on collision. Because the code is the document id, a clash shows up
    // as a failed create rather than as two trips sharing a code.
    var code = Invite.generateCode();
    var attempts = 0;
    while (_backend.invites.containsKey(code)) {
      if (++attempts > 5) {
        throw const UnknownError(
          message: "Couldn't generate an invite code. Please try again.",
        );
      }
      code = Invite.generateCode();
    }

    final invite = Invite(
      code: code,
      tripId: tripId,
      createdBy: uid,
      maxUses: maxUses,
      usedCount: 0,
      revoked: false,
      createdAt: DateTime.now().toUtc(),
      expiresAt: expiresAt?.toUtc(),
    );
    _backend.invites[code] = invite;
    _backend.emitChange();
    return invite;
  }

  @override
  Stream<List<Invite>> watchInvites(String tripId) {
    return _backend.watch('watchInvites', () {
      return _backend.invites.values
          .where((invite) => invite.tripId == tripId && !invite.revoked)
          .toList(growable: false);
    });
  }

  @override
  Future<void> revokeInvite({
    required String tripId,
    required String code,
  }) async {
    await _backend.guard('revokeInvite');
    final uid = _backend.requireUid();
    _backend.requireOrganizer(tripId, uid);

    final invite = _backend.invites[Invite.normalizeCode(code)];
    if (invite == null || invite.tripId != tripId) {
      throw const NotFoundError(message: 'That invite no longer exists.');
    }
    _backend.invites[invite.code] = invite.copyWith(revoked: true);
    _backend.emitChange();
  }

  @override
  Future<Trip> joinTrip({required String code}) async {
    await _backend.guard('joinTrip');
    final uid = _backend.requireUid();

    final normalized = Invite.normalizeCode(code);
    if (normalized.isEmpty) {
      throw const InvalidInputError(message: 'Enter an invite code.');
    }

    final invite = _backend.invites[normalized];
    if (invite == null) {
      throw const NotFoundError(
        message: "That invite code doesn't exist. Check it and try again.",
      );
    }

    final rejection = invite.validate(now: DateTime.now().toUtc());
    if (rejection != null) {
      throw InvalidInputError(
        message: switch (rejection) {
          InviteRejection.expired => 'That invite code has expired.',
          InviteRejection.revoked => 'That invite code was cancelled.',
          InviteRejection.exhausted =>
            'That invite code has already been fully used.',
        },
      );
    }

    final trip = _backend.trips[invite.tripId];
    if (trip == null) {
      throw const NotFoundError(message: 'That trip no longer exists.');
    }
    if (_backend.memberOf(trip.id, uid) != null) {
      throw const AlreadyExistsError(
        message: "You're already a member of this trip.",
      );
    }

    // Membership and usedCount increment together, so two people redeeming a
    // single-use code cannot both get in.
    final user = _backend.users[uid];
    final now = DateTime.now().toUtc();
    _backend.putMember(
      TripMember(
        uid: uid,
        tripId: trip.id,
        role: TripRole.member,
        displayName: user?.displayName ?? 'Traveller',
        photoUrl: user?.photoUrl,
        joinedAt: now,
        // Recorded so the security rule can verify this join against the
        // invite it claims to have used.
        joinedWithCode: normalized,
      ),
    );
    _backend.invites[normalized] = invite.copyWith(
      usedCount: invite.usedCount + 1,
    );
    _backend.addActivity(
      tripId: trip.id,
      type: ActivityType.memberJoined,
      actorId: uid,
      summary: '${user?.displayName ?? 'Someone'} joined the trip',
      entityId: uid,
    );

    _backend.emitChange();
    return _backend.trips[trip.id]!;
  }

  @override
  Future<void> removeMember({
    required String tripId,
    required String uid,
  }) async {
    await _backend.guard('removeMember');
    final actorId = _backend.requireUid();
    _backend.requireOrganizer(tripId, actorId);

    final target = _backend.memberOf(tripId, uid);
    if (target == null) {
      throw const NotFoundError(message: 'That person is not in this trip.');
    }
    _assertNotLastOrganizer(tripId, uid);

    _backend.dropMember(tripId, uid);
    _backend.addActivity(
      tripId: tripId,
      type: ActivityType.memberRemoved,
      actorId: actorId,
      summary:
          '${_backend.users[actorId]?.displayName ?? 'An organizer'} removed '
          '${target.displayName} from the trip',
      entityId: uid,
    );
    _backend.emitChange();
  }

  @override
  Future<void> leaveTrip(String tripId) async {
    await _backend.guard('leaveTrip');
    final uid = _backend.requireUid();
    final member = _backend.requireMember(tripId, uid);
    _assertNotLastOrganizer(tripId, uid);

    _backend.dropMember(tripId, uid);
    _backend.addActivity(
      tripId: tripId,
      type: ActivityType.memberRemoved,
      actorId: uid,
      summary: '${member.displayName} left the trip',
      entityId: uid,
    );
    _backend.emitChange();
  }

  @override
  Future<void> updateMemberRole({
    required String tripId,
    required String uid,
    required TripRole role,
  }) async {
    await _backend.guard('updateMemberRole');
    final actorId = _backend.requireUid();
    _backend.requireOrganizer(tripId, actorId);

    final target = _backend.memberOf(tripId, uid);
    if (target == null) {
      throw const NotFoundError(message: 'That person is not in this trip.');
    }
    if (role == TripRole.unknown) {
      throw const InvalidInputError(message: 'Pick a valid role.');
    }
    // Demoting the last organizer strands the trip just as surely as letting
    // them leave.
    if (target.role == TripRole.organizer && role != TripRole.organizer) {
      _assertNotLastOrganizer(tripId, uid);
    }

    _backend.members[tripId]![uid] = target.copyWith(role: role);
    _backend.addActivity(
      tripId: tripId,
      type: ActivityType.memberRoleChanged,
      actorId: actorId,
      summary: '${target.displayName} is now a ${role.wire}',
      entityId: uid,
    );
    _backend.emitChange();
  }

  /// A trip whose last organizer leaves can never be administered again — no
  /// one could close a poll, confirm a settlement, or invite anyone. Refused
  /// rather than silently orphaning the trip.
  void _assertNotLastOrganizer(String tripId, String uid) {
    final roster = _backend.members[tripId];
    if (roster == null) return;

    final target = roster[uid];
    if (target?.role != TripRole.organizer) return;

    final otherOrganizers = roster.values
        .where((m) => m.uid != uid && m.role == TripRole.organizer)
        .length;
    if (otherOrganizers == 0) {
      throw const InvalidInputError(
        message: 'Make someone else an organizer first — a trip needs one.',
      );
    }
  }
}

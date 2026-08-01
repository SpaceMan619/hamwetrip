import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../../core/error/app_error.dart';
import '../../domain/models/activity_event.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/invite.dart';
import '../../domain/models/trip.dart';
import '../../domain/models/trip_member.dart';
import '../../domain/repositories/trip_repository.dart';
import 'firebase_error_mapper.dart';

/// Firebase-backed [TripRepository].
///
/// ## Why activity events are never in the same batch/transaction as a
/// membership create
///
/// Firestore evaluates every write inside one batch or transaction against
/// the database state from *before* that commit — the deployed
/// `firestore.rules` says this in so many words for the organizer-bootstrap
/// case. The activity-create rule requires `isMember(tripId)` for the actor.
/// In [createTrip] and [joinTrip] the actor's own membership document is
/// exactly what is being created in that same atomic write, so from the
/// rule's point of view it does not exist yet — bundling the activity event
/// in would be rejected. The reachability invariant ("a trip is never
/// reachable with no members") is fully guaranteed by the trip+member (or
/// member+invite-increment) commit alone; the audit-trail entry is a
/// deliberate follow-up write immediately after, not part of that atomic
/// unit.
class FirebaseTripRepository implements TripRepository {
  FirebaseTripRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final fb_auth.FirebaseAuth _auth;

  CollectionReference<Map<String, Object?>> get _trips =>
      _firestore.collection('trips');

  CollectionReference<Map<String, Object?>> get _invites =>
      _firestore.collection('invites');

  CollectionReference<Map<String, Object?>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, Object?>> _membersOf(String tripId) =>
      _trips.doc(tripId).collection('members');

  DocumentReference<Map<String, Object?>> _memberDoc(
    String tripId,
    String uid,
  ) => _membersOf(tripId).doc(uid);

  CollectionReference<Map<String, Object?>> _activityOf(String tripId) =>
      _trips.doc(tripId).collection('activity');

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const AuthError(message: 'You need to be signed in to do that.');
    }
    return uid;
  }

  int _byRecency(Trip a, Trip b) {
    final left = a.createdAt;
    final right = b.createdAt;
    if (left == null && right == null) return a.name.compareTo(b.name);
    if (left == null) return 1;
    if (right == null) return -1;
    return right.compareTo(left);
  }

  int _byRoleThenName(TripMember a, TripMember b) {
    if (a.role != b.role) {
      if (a.role == TripRole.organizer) return -1;
      if (b.role == TripRole.organizer) return 1;
    }
    return a.displayName.compareTo(b.displayName);
  }

  @override
  Stream<List<Trip>> watchMyTrips() {
    // Captured once at subscription time. A sign-in/out mid-subscription is
    // handled one layer up, by the provider graph rebuilding this repository
    // subtree off `authState()` — not by this stream switching identities.
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const <Trip>[]);

    return _firestore
        .collectionGroup('members')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .asyncMap(_loadTripsFor)
        .mapFirebaseErrors();
  }

  Future<List<Trip>> _loadTripsFor(
    QuerySnapshot<Map<String, Object?>> membershipSnap,
  ) async {
    if (membershipSnap.docs.isEmpty) return const <Trip>[];
    final tripIds = membershipSnap.docs
        .map((doc) => doc.reference.parent.parent!.id)
        .toSet();
    final tripSnaps = await Future.wait(
      tripIds.map((id) => _trips.doc(id).get()),
    );
    final trips =
        tripSnaps
            .where((snap) => snap.exists)
            .map((snap) => Trip.fromMap(snap.id, snap.data()!))
            // Archiving is how a trip is "deleted" — see updateTrip's
            // organizer-only status change and the firestore.rules comment on
            // why trips/{tripId} can never be hard-deleted. Filtered here
            // rather than left to the UI, so nothing that lists trips has to
            // remember to exclude them.
            .where((trip) => trip.status != TripStatus.archived)
            .toList()
          ..sort(_byRecency);
    return trips;
  }

  @override
  Stream<Trip?> watchTrip(String tripId) {
    return _trips
        .doc(tripId)
        .snapshots()
        .transform(
          StreamTransformer<
            DocumentSnapshot<Map<String, Object?>>,
            Trip?
          >.fromHandlers(
            handleData: (snap, sink) {
              sink.add(
                snap.exists ? Trip.fromMap(snap.id, snap.data()!) : null,
              );
            },
            handleError: (Object error, StackTrace stackTrace, sink) {
              if (error is FirebaseException &&
                  error.code == 'permission-denied') {
                // Documented contract: losing access reads the same as the trip
                // being deleted, so the dashboard navigates away either way.
                sink.add(null);
                return;
              }
              sink.addError(mapFirebaseError(error), stackTrace);
            },
          ),
        );
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
    final uid = _requireUid();
    final trimmedName = name.trim();
    final trimmedDestination = destination.trim();

    if (trimmedName.isEmpty) {
      throw const InvalidInputError(message: 'Give your trip a name.');
    }
    if (trimmedDestination.isEmpty) {
      throw const InvalidInputError(message: 'Where are you going?');
    }
    if (startDate != null && endDate != null && endDate.isBefore(startDate)) {
      throw const InvalidInputError(
        message: 'The end date cannot be before the start date.',
      );
    }

    try {
      // requestId doubles as the trip's document id, which is what makes a
      // repeated call idempotent: the second attempt writes the same two
      // documents to the same two paths rather than creating a second trip.
      //
      // Deliberately no existence pre-check. `allow get` on a trip requires
      // isMember(tripId), and on a trip that does not exist yet nobody is a
      // member — so reading it first is denied for the very person about to
      // create it, and the create never happens. Idempotency comes from the
      // document id, not from a read.
      final tripRef = _trips.doc(requestId);

      final now = DateTime.now().toUtc();
      final trip = Trip(
        id: tripRef.id,
        name: trimmedName,
        destination: trimmedDestination,
        ownerId: uid,
        currency: currency,
        status: TripStatus.planning,
        startDate: startDate?.toUtc(),
        endDate: endDate?.toUtc(),
        createdAt: now,
        updatedAt: now,
      );
      final tripData = trip.toMap()
        ..['createdAt'] = FieldValue.serverTimestamp()
        ..['updatedAt'] = FieldValue.serverTimestamp();

      final me = await _users.doc(uid).get();
      final creatorProfile = AppUser.fromMap(me.id, me.data() ?? const {});
      final creatorName = creatorProfile.displayName.isEmpty
          ? 'Organizer'
          : creatorProfile.displayName;
      final member = TripMember(
        uid: uid,
        tripId: tripRef.id,
        role: TripRole.organizer,
        displayName: creatorName,
        photoUrl: creatorProfile.photoUrl,
        joinedAt: now,
      );
      final memberData = member.toMap()
        ..['joinedAt'] = FieldValue.serverTimestamp();

      final batch = _firestore.batch();
      batch.set(tripRef, tripData);
      batch.set(_memberDoc(tripRef.id, uid), memberData);

      try {
        await batch.commit();
      } on FirebaseException catch (error) {
        if (error.code != 'permission-denied') rethrow;

        // This is what a genuine repeat looks like. The first call already
        // created the trip, so the second one is an *update* as far as the
        // rules are concerned — and the update rule refuses to let createdAt
        // be restamped. Reading the trip back is permitted now that the first
        // call made us a member, so a repeat resolves to the original trip
        // instead of an error.
        final existing = await tripRef.get();
        if (existing.exists) {
          return Trip.fromMap(existing.id, existing.data()!);
        }
        rethrow;
      }

      await _writeActivity(
        tripId: tripRef.id,
        type: ActivityType.tripCreated,
        actorId: uid,
        actorName: creatorName,
        summary: '$creatorName created the trip',
        entityId: tripRef.id,
      );

      return trip;
    } catch (error) {
      throw mapFirebaseError(error);
    }
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
    final uid = _requireUid();
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isEmpty) {
      throw const InvalidInputError(message: 'Give your trip a name.');
    }

    try {
      await _requireOrganizer(tripId, uid);

      final updates = <String, Object?>{
        'name': ?trimmedName,
        if (destination != null) 'destination': destination.trim(),
        if (startDate != null) 'startDate': startDate.toUtc(),
        if (endDate != null) 'endDate': endDate.toUtc(),
        if (status != null) 'status': status.wire,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final tripRef = _trips.doc(tripId);
      await tripRef.update(updates);
      final snap = await tripRef.get();
      if (!snap.exists) throw const NotFoundError();
      return Trip.fromMap(snap.id, snap.data()!);
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Stream<List<TripMember>> watchMembers(String tripId) {
    return _membersOf(tripId)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((d) => TripMember.fromMap(tripId, d.id, d.data()))
                  .toList()
                ..sort(_byRoleThenName),
        )
        .mapFirebaseErrors();
  }

  @override
  Stream<TripMember?> watchMyMembership(String tripId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);

    return _memberDoc(tripId, uid).snapshots().transform(
      StreamTransformer<
        DocumentSnapshot<Map<String, Object?>>,
        TripMember?
      >.fromHandlers(
        handleData: (snap, sink) {
          sink.add(
            snap.exists
                ? TripMember.fromMap(tripId, snap.id, snap.data()!)
                : null,
          );
        },
        handleError: (Object error, StackTrace stackTrace, sink) {
          if (error is FirebaseException && error.code == 'permission-denied') {
            sink.add(null);
            return;
          }
          sink.addError(mapFirebaseError(error), stackTrace);
        },
      ),
    );
  }

  Future<TripMember> _requireMember(String tripId, String uid) async {
    final snap = await _memberDoc(tripId, uid).get();
    if (!snap.exists) {
      throw const PermissionDeniedError(
        message: "You're not a member of this trip.",
      );
    }
    return TripMember.fromMap(tripId, snap.id, snap.data()!);
  }

  Future<TripMember> _requireOrganizer(String tripId, String uid) async {
    final member = await _requireMember(tripId, uid);
    if (!member.role.canManageMembership) {
      throw const PermissionDeniedError(
        message: 'Only a trip organizer can do that.',
      );
    }
    return member;
  }

  /// Builds the document reference and payload for an audit-trail event,
  /// without writing it.
  ///
  /// Split out from [_writeActivity] so an event can also be enlisted into a
  /// caller's transaction — which [leaveTrip] needs, because it is removing
  /// the very membership that authorizes the event.
  (DocumentReference<Map<String, Object?>>, Map<String, Object?>)
  _activityWrite({
    required String tripId,
    required ActivityType type,
    required String actorId,
    required String summary,
    String? actorName,
    String? entityId,
  }) {
    final ref = _activityOf(tripId).doc();
    final event = ActivityEvent(
      id: ref.id,
      tripId: tripId,
      type: type,
      actorId: actorId,
      actorName: actorName,
      summary: summary,
      entityId: entityId,
    );
    return (ref, event.toMap()..['createdAt'] = FieldValue.serverTimestamp());
  }

  /// Best-effort audit-trail write. Failing to record an event never rolls
  /// back — or blocks — the mutation it describes; see the class doc for why
  /// it cannot share a commit with the write that created the actor's own
  /// membership.
  Future<void> _writeActivity({
    required String tripId,
    required ActivityType type,
    required String actorId,
    required String summary,
    String? actorName,
    String? entityId,
  }) async {
    final (ref, data) = _activityWrite(
      tripId: tripId,
      type: type,
      actorId: actorId,
      summary: summary,
      actorName: actorName,
      entityId: entityId,
    );
    await ref.set(data);
  }

  // ---------------------------------------------------------------------
  // Invites & membership
  // ---------------------------------------------------------------------

  @override
  Future<Invite> createInvite({
    required String tripId,
    int maxUses = Invite.unlimitedUses,
    DateTime? expiresAt,
  }) async {
    final uid = _requireUid();
    if (maxUses != Invite.unlimitedUses && maxUses < 1) {
      throw const InvalidInputError(
        message: 'An invite has to allow at least one person.',
      );
    }

    try {
      await _requireOrganizer(tripId, uid);

      // The code is the document id (see Invite's class doc), so a collision
      // surfaces here as "doc already exists" rather than as two trips
      // silently sharing a code.
      var code = Invite.generateCode();
      var attempts = 0;
      late DocumentReference<Map<String, Object?>> inviteRef;
      while (true) {
        inviteRef = _invites.doc(code);
        final existing = await inviteRef.get();
        if (!existing.exists) break;
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
      final data = invite.toMap()..['createdAt'] = FieldValue.serverTimestamp();
      await inviteRef.set(data);
      return invite;
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Stream<List<Invite>> watchInvites(String tripId) {
    // Authorized by `allow list: if isOrganizer(resource.data.tripId)` on the
    // top-level `invites` collection. The tripId filter below is not optional:
    // the rule is evaluated per candidate document, so a query that reached
    // beyond this trip would be rejected on the first document belonging to a
    // trip the caller does not organize.
    return _invites
        .where('tripId', isEqualTo: tripId)
        .where('revoked', isEqualTo: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Invite.fromMap(d.id, d.data()))
              .toList(growable: false),
        )
        .mapFirebaseErrors();
  }

  @override
  Future<void> revokeInvite({
    required String tripId,
    required String code,
  }) async {
    final uid = _requireUid();
    final normalized = Invite.normalizeCode(code);

    try {
      await _requireOrganizer(tripId, uid);

      final inviteRef = _invites.doc(normalized);
      final snap = await inviteRef.get();
      final data = snap.data();
      if (!snap.exists || data == null || data['tripId'] != tripId) {
        throw const NotFoundError(message: 'That invite no longer exists.');
      }
      await inviteRef.update({'revoked': true});
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<Trip> joinTrip({required String code}) async {
    final uid = _requireUid();
    final normalized = Invite.normalizeCode(code);
    if (normalized.isEmpty) {
      throw const InvalidInputError(message: 'Enter an invite code.');
    }

    try {
      final inviteRef = _invites.doc(normalized);
      final me = await _users.doc(uid).get();
      final joinerProfile = AppUser.fromMap(me.id, me.data() ?? const {});
      final joinerName = joinerProfile.displayName.isEmpty
          ? 'Traveller'
          : joinerProfile.displayName;
      final joinerPhoto = joinerProfile.photoUrl;

      final tripId = await _firestore.runTransaction<String>((
        transaction,
      ) async {
        final inviteSnap = await transaction.get(inviteRef);
        if (!inviteSnap.exists) {
          throw const NotFoundError(
            message: "That invite code doesn't exist. Check it and try again.",
          );
        }
        final data = inviteSnap.data()!;
        final invite = Invite.fromMap(inviteRef.id, data);

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

        final memberRef = _memberDoc(invite.tripId, uid);
        final memberSnap = await transaction.get(memberRef);
        if (memberSnap.exists) {
          throw const AlreadyExistsError(
            message: "You're already a member of this trip.",
          );
        }

        final tripRef = _trips.doc(invite.tripId);
        final tripSnap = await transaction.get(tripRef);
        if (!tripSnap.exists) {
          throw const NotFoundError(message: 'That trip no longer exists.');
        }

        final member = TripMember(
          uid: uid,
          tripId: invite.tripId,
          role: TripRole.member,
          displayName: joinerName,
          photoUrl: joinerPhoto,
          joinedAt: DateTime.now().toUtc(),
          joinedWithCode: normalized,
        );
        final memberData = member.toMap()
          ..['joinedAt'] = FieldValue.serverTimestamp();

        // Membership and usedCount move together, so two people racing a
        // single-use code cannot both get in — the loser's transaction
        // retries against the post-increment invite and fails validate().
        transaction.set(memberRef, memberData);
        transaction.update(inviteRef, {'usedCount': invite.usedCount + 1});

        return invite.tripId;
      });

      await _writeActivity(
        tripId: tripId,
        type: ActivityType.memberJoined,
        actorId: uid,
        actorName: joinerName,
        summary: '$joinerName joined the trip',
        entityId: uid,
      );

      final tripSnap = await _trips.doc(tripId).get();
      return Trip.fromMap(tripSnap.id, tripSnap.data()!);
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<void> removeMember({
    required String tripId,
    required String uid,
  }) async {
    final actorId = _requireUid();

    try {
      await _requireOrganizer(tripId, actorId);
      final target = await _memberDoc(tripId, uid).get();
      if (!target.exists) {
        throw const NotFoundError(message: 'That person is not in this trip.');
      }
      final targetMember = TripMember.fromMap(
        tripId,
        target.id,
        target.data()!,
      );

      await _runIfNotLastOrganizer(
        tripId: tripId,
        uid: uid,
        currentRole: targetMember.role,
        nextRole: null,
        write: (transaction, memberRef) => transaction.delete(memberRef),
      );

      await _writeActivity(
        tripId: tripId,
        type: ActivityType.memberRemoved,
        actorId: actorId,
        summary: '${targetMember.displayName} was removed from the trip',
        entityId: uid,
      );
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<void> leaveTrip(String tripId) async {
    final uid = _requireUid();

    try {
      final member = await _requireMember(tripId, uid);

      // The audit event rides inside the same transaction as the delete.
      //
      // It cannot be written afterwards: the activity create rule requires
      // isMember(tripId), and this member has just stopped being one, so the
      // event is denied and the caller sees a failure for a departure that
      // actually succeeded. It cannot simply be written beforehand either —
      // the last-organizer check below may reject the leave, which would
      // leave a "left the trip" event behind for someone still in the trip.
      //
      // Inside the transaction both writes are evaluated against the state
      // from before the commit, where the membership still exists, so the
      // event is authorized and a rejected leave records nothing.
      final (activityRef, activityData) = _activityWrite(
        tripId: tripId,
        type: ActivityType.memberRemoved,
        actorId: uid,
        actorName: member.displayName,
        summary: '${member.displayName} left the trip',
        entityId: uid,
      );

      await _runIfNotLastOrganizer(
        tripId: tripId,
        uid: uid,
        currentRole: member.role,
        nextRole: null,
        write: (transaction, memberRef) {
          transaction.set(activityRef, activityData);
          transaction.delete(memberRef);
        },
      );
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<void> updateMemberRole({
    required String tripId,
    required String uid,
    required TripRole role,
  }) async {
    final actorId = _requireUid();
    if (role == TripRole.unknown) {
      throw const InvalidInputError(message: 'Pick a valid role.');
    }

    try {
      await _requireOrganizer(tripId, actorId);
      final target = await _memberDoc(tripId, uid).get();
      if (!target.exists) {
        throw const NotFoundError(message: 'That person is not in this trip.');
      }
      final targetMember = TripMember.fromMap(
        tripId,
        target.id,
        target.data()!,
      );

      await _runIfNotLastOrganizer(
        tripId: tripId,
        uid: uid,
        currentRole: targetMember.role,
        nextRole: role,
        write: (transaction, memberRef) =>
            transaction.update(memberRef, {'role': role.wire}),
      );

      await _writeActivity(
        tripId: tripId,
        type: ActivityType.memberRoleChanged,
        actorId: actorId,
        summary: '${targetMember.displayName} is now a ${role.wire}',
        entityId: uid,
      );
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  /// Guards leaving/removal/demotion against stranding a trip with zero
  /// organizers, then performs [write] — atomically, so the check and the
  /// write can never observe different states.
  ///
  /// Rules cannot express this: they cannot count sibling documents, so
  /// nothing server-side stops the *last* organizer specifically (only that
  /// members can delete themselves or be deleted by an organizer at all).
  /// The Dart SDK's `Transaction.get()` only reads single documents, not
  /// queries, so a live organizer count can't be read inside the
  /// transaction. Instead: query the current organizer roster first (a plain,
  /// non-transactional read — just candidate discovery, not the security
  /// decision), then re-`get()` exactly those candidate documents inside the
  /// transaction and decide from that re-read. Any concurrent change to one
  /// of those specific documents aborts and retries the transaction, so the
  /// allow/deny decision and the write are never split by a race.
  Future<void> _runIfNotLastOrganizer({
    required String tripId,
    required String uid,
    required TripRole currentRole,
    required TripRole? nextRole,
    required void Function(
      Transaction transaction,
      DocumentReference<Map<String, Object?>> memberRef,
    )
    write,
  }) async {
    final losesOrganizer =
        currentRole == TripRole.organizer && nextRole != TripRole.organizer;
    if (!losesOrganizer) {
      await _firestore.runTransaction((transaction) async {
        write(transaction, _memberDoc(tripId, uid));
      });
      return;
    }

    final candidates = await _membersOf(
      tripId,
    ).where('role', isEqualTo: TripRole.organizer.wire).get();
    final otherOrganizerRefs = candidates.docs
        .map((d) => d.reference)
        .where((ref) => ref.id != uid)
        .toList();

    await _firestore.runTransaction((transaction) async {
      // Re-read every candidate inside the transaction: one of them may have
      // been demoted or removed since the query above ran.
      var remainingOrganizers = 0;
      for (final ref in otherOrganizerRefs) {
        final snap = await transaction.get(ref);
        if (snap.exists && snap.data()?['role'] == TripRole.organizer.wire) {
          remainingOrganizers++;
        }
      }
      if (remainingOrganizers == 0) {
        throw const InvalidInputError(
          message: 'Make someone else an organizer first — a trip needs one.',
        );
      }
      write(transaction, _memberDoc(tripId, uid));
    });
  }
}

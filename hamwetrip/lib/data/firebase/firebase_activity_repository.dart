import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../../domain/models/activity_event.dart';
import '../../domain/repositories/activity_repository.dart';
import 'firebase_error_mapper.dart';

/// Firebase-backed [ActivityRepository].
///
/// [watchMyActivity] merges each of the caller's trips client-side rather
/// than running one `collectionGroup('activity')` query: each per-trip query
/// is a plain single-collection query Firestore indexes automatically, so
/// this needs no collection-group index. The per-trip fetch is itself capped
/// at [limit] events, so the merge is bounded even when someone belongs to
/// many trips.
class FirebaseActivityRepository implements ActivityRepository {
  FirebaseActivityRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final fb_auth.FirebaseAuth _auth;

  CollectionReference<Map<String, Object?>> _activityOf(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('activity');

  /// Newest first. A just-written event (null [ActivityEvent.createdAt],
  /// still awaiting the server timestamp) sorts to the top rather than to the
  /// bottom, so it appears immediately instead of after the round trip.
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
    return _activityOf(tripId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ActivityEvent.fromMap(tripId, d.id, d.data()))
              .toList(growable: false),
        )
        .mapFirebaseErrors();
  }

  @override
  Stream<List<ActivityEvent>> watchMyActivity({int limit = 30}) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const <ActivityEvent>[]);

    final controller = StreamController<List<ActivityEvent>>.broadcast();
    final perTrip = <String, List<ActivityEvent>>{};
    final tripSubs = <String, StreamSubscription<List<ActivityEvent>>>{};
    StreamSubscription<QuerySnapshot<Map<String, Object?>>>? membershipSub;

    void emitMerged() {
      final merged = perTrip.values.expand((events) => events).toList()
        ..sort(_byRecency);
      controller.add(merged.take(limit).toList(growable: false));
    }

    void subscribeTrip(String tripId) {
      tripSubs[tripId] = watchActivity(tripId, limit: limit).listen(
        (events) {
          perTrip[tripId] = events;
          emitMerged();
        },
        onError: (Object error, StackTrace stackTrace) {
          controller.addError(error, stackTrace);
        },
      );
    }

    void unsubscribeTrip(String tripId) {
      tripSubs.remove(tripId)?.cancel();
      perTrip.remove(tripId);
    }

    controller.onListen = () {
      membershipSub = _firestore
          .collectionGroup('members')
          .where('uid', isEqualTo: uid)
          .snapshots()
          .listen(
            (membershipSnap) {
              final tripIds = membershipSnap.docs
                  .map((doc) => doc.reference.parent.parent!.id)
                  .toSet();

              for (final tripId in tripIds) {
                if (!tripSubs.containsKey(tripId)) subscribeTrip(tripId);
              }
              for (final tripId in tripSubs.keys.toList()) {
                if (!tripIds.contains(tripId)) unsubscribeTrip(tripId);
              }
              // Recomputes immediately so a trip the user just left drops out
              // of the merged feed right away, rather than lingering until
              // some other trip's listener happens to fire next.
              emitMerged();
            },
            onError: (Object error, StackTrace stackTrace) {
              controller.addError(mapFirebaseError(error), stackTrace);
            },
          );
    };

    controller.onCancel = () async {
      await membershipSub?.cancel();
      for (final sub in tripSubs.values) {
        await sub.cancel();
      }
    };

    return controller.stream;
  }

  @override
  Future<void> recordEvent(ActivityEvent event) async {
    // Still a plain client write in Phase 2 — the interface's own doc
    // comment is explicit that this only becomes PermissionDeniedError once
    // the P3-17 Cloud Function triggers land and the rules close this path.
    try {
      final ref = event.id.isEmpty
          ? _activityOf(event.tripId).doc()
          : _activityOf(event.tripId).doc(event.id);
      final data = event.toMap()..['createdAt'] = FieldValue.serverTimestamp();
      await ref.set(data);
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }
}

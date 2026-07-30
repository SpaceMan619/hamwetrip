import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../../core/error/app_error.dart';
import '../../domain/models/app_user.dart';
import '../../domain/repositories/user_repository.dart';
import 'firebase_error_mapper.dart';

/// Firebase-backed [UserRepository]. Reads and writes `users/{uid}`.
class FirebaseUserRepository implements UserRepository {
  FirebaseUserRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final fb_auth.FirebaseAuth _auth;

  /// Writes to Firestore land in a batch of at most this many operations —
  /// the hard ceiling Firestore enforces per commit.
  static const _maxBatchWrites = 500;

  CollectionReference<Map<String, Object?>> get _users =>
      _firestore.collection('users');

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const AuthError(message: 'You need to be signed in to do that.');
    }
    return uid;
  }

  @override
  Stream<AppUser?> watchUser(String uid) {
    return _users
        .doc(uid)
        .snapshots()
        .map(
          (snap) => snap.exists ? AppUser.fromMap(snap.id, snap.data()!) : null,
        )
        .mapFirebaseErrors();
  }

  @override
  Future<AppUser?> getUser(String uid) async {
    try {
      final snap = await _users.doc(uid).get();
      return snap.exists ? AppUser.fromMap(snap.id, snap.data()!) : null;
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<List<AppUser>> getUsers(List<String> uids) async {
    try {
      // One get per uid rather than a chunked `whereIn` query: trip rosters
      // are small, and this keeps the "some ids may be missing" contract
      // trivial to satisfy without dealing with the 30-value query cap.
      final snapshots = await Future.wait(
        uids.map((uid) => _users.doc(uid).get()),
      );
      return snapshots
          .where((snap) => snap.exists)
          .map((snap) => AppUser.fromMap(snap.id, snap.data()!))
          .toList(growable: false);
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<AppUser> updateProfile({
    String? displayName,
    String? phone,
    String? photoUrl,
    bool clearPhone = false,
    bool clearPhotoUrl = false,
  }) async {
    final uid = _requireUid();
    final trimmedName = displayName?.trim();
    if (trimmedName != null && trimmedName.isEmpty) {
      throw const InvalidInputError(message: 'Your name cannot be empty.');
    }

    final updates = <String, Object?>{
      'displayName': ?trimmedName,
      if (clearPhone) 'phone': FieldValue.delete() else 'phone': ?phone,
      if (clearPhotoUrl)
        'photoUrl': FieldValue.delete()
      else
        'photoUrl': ?photoUrl,
    };

    try {
      final userDoc = _users.doc(uid);
      if (updates.isNotEmpty) await userDoc.update(updates);

      // The trip-mate roster denormalizes displayName so a member list
      // renders in one read — see TripMember. A rename has to fan out there,
      // or every roster in every trip this person belongs to goes stale.
      if (trimmedName != null) await _fanOutDisplayName(uid, trimmedName);

      final snap = await userDoc.get();
      if (!snap.exists) throw const NotFoundError();
      return AppUser.fromMap(snap.id, snap.data()!);
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  Future<void> _fanOutDisplayName(String uid, String displayName) async {
    final memberships = await _firestore
        .collectionGroup('members')
        .where('uid', isEqualTo: uid)
        .get();

    for (
      var offset = 0;
      offset < memberships.docs.length;
      offset += _maxBatchWrites
    ) {
      final chunk = memberships.docs.skip(offset).take(_maxBatchWrites);
      final batch = _firestore.batch();
      for (final doc in chunk) {
        batch.update(doc.reference, {'displayName': displayName});
      }
      await batch.commit();
    }
  }

  @override
  Future<void> updateNotificationPrefs({required bool enabled}) async {
    final uid = _requireUid();
    try {
      await _users.doc(uid).update({'notificationsEnabled': enabled});
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }
}

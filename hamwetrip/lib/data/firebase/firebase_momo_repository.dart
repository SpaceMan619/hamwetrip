import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../../core/error/app_error.dart';
import '../../data/models/momo_transaction.dart';
import '../../domain/repositories/momo_repository.dart';
import 'firebase_error_mapper.dart';

/// Firebase-backed [MomoRepository].
///
/// MoMo transactions live as a subcollection under each trip:
/// `trips/{tripId}/payments/{txId}`.
class FirebaseMomoRepository implements MomoRepository {
  FirebaseMomoRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final fb_auth.FirebaseAuth _auth;

  CollectionReference<Map<String, Object?>> _txOf(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('payments');

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const AuthError(message: 'You need to be signed in to do that.');
    }
    return uid;
  }

  @override
  Stream<List<MomoTransaction>> watchTransactions(String tripId) {
    return _txOf(tripId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MomoTransaction.fromMap(d.id, d.data()))
              .toList(),
        )
        .mapFirebaseErrors();
  }

  @override
  Future<void> payNow({
    required String tripId,
    required String transactionId,
  }) async {
    _requireUid();
    try {
      await _txOf(
        tripId,
      ).doc(transactionId).update({'status': MomoStatus.completed.name});
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<void> requestPayment({
    required String tripId,
    required String transactionId,
  }) async {
    _requireUid();
    try {
      await _txOf(
        tripId,
      ).doc(transactionId).update({'status': MomoStatus.completed.name});
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }
}

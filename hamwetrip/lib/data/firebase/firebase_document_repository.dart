import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../../core/error/app_error.dart';
import '../../data/models/document.dart';
import '../../domain/repositories/document_repository.dart';
import 'firebase_error_mapper.dart';

/// Firebase-backed [DocumentRepository].
///
/// Documents live as a subcollection under each trip:
/// `trips/{tripId}/documents/{docId}`.
class FirebaseDocumentRepository implements DocumentRepository {
  FirebaseDocumentRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final fb_auth.FirebaseAuth _auth;

  CollectionReference<Map<String, Object?>> _docsOf(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('documents');

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const AuthError(message: 'You need to be signed in to do that.');
    }
    return uid;
  }

  @override
  Stream<List<TripDocument>> watchDocuments(String tripId) {
    return _docsOf(tripId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => TripDocument.fromMap(d.id, d.data()))
              .toList(),
        )
        .mapFirebaseErrors();
  }

  @override
  Future<TripDocument> uploadDocument({
    required String tripId,
    required String title,
    required String category,
    required DocType type,
    required String uploadedBy,
    required String uploadedByInitials,
    required String fileSize,
  }) async {
    _requireUid();
    try {
      final ref = _docsOf(tripId).doc();
      final doc = TripDocument(
        id: ref.id,
        title: title,
        category: category,
        type: type,
        uploadedBy: uploadedBy,
        uploadedByInitials: uploadedByInitials,
        fileSize: fileSize,
        date: DateTime.now(),
      );
      final data = doc.toMap()..['createdAt'] = FieldValue.serverTimestamp();
      await ref.set(data);
      return doc;
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<void> deleteDocument({
    required String tripId,
    required String docId,
  }) async {
    _requireUid();
    try {
      await _docsOf(tripId).doc(docId).delete();
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }
}

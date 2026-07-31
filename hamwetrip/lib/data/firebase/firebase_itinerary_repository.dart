import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../../core/error/app_error.dart';
import '../../data/models/itinerary.dart';
import '../../domain/repositories/itinerary_repository.dart';
import 'firebase_error_mapper.dart';

/// Firebase-backed [ItineraryRepository].
///
/// Itinerary days live as a subcollection under each trip:
/// `trips/{tripId}/itinerary/{dayId}`.
/// Each day document contains an `items` array with the day's items.
class FirebaseItineraryRepository implements ItineraryRepository {
  FirebaseItineraryRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final fb_auth.FirebaseAuth _auth;

  CollectionReference<Map<String, Object?>> _daysOf(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('itinerary');

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const AuthError(message: 'You need to be signed in to do that.');
    }
    return uid;
  }

  @override
  Stream<List<ItineraryDay>> watchItinerary(String tripId) {
    return _daysOf(tripId)
        .orderBy('date')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ItineraryDay.fromMap(d.data())).toList(),
        )
        .mapFirebaseErrors();
  }

  @override
  Future<void> toggleItemCompletion({
    required String tripId,
    required String itemId,
  }) async {
    _requireUid();
    try {
      // Find the day that contains this item, then toggle its `isCompleted`
      // field inside the items array.
      final daysSnap = await _daysOf(tripId).get();
      for (final dayDoc in daysSnap.docs) {
        final day = ItineraryDay.fromMap(dayDoc.data());
        final itemIndex = day.items.indexWhere((i) => i.id == itemId);
        if (itemIndex != -1) {
          final items = day.items.map((i) => i.toMap()).toList();
          items[itemIndex]['isCompleted'] =
              !(items[itemIndex]['isCompleted'] as bool? ?? false);
          await dayDoc.reference.update({'items': items});
          return;
        }
      }
      throw const NotFoundError(message: 'That itinerary item was not found.');
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<ItineraryItem> createItem({
    required String tripId,
    required String dayId,
    required ItineraryItem item,
  }) async {
    _requireUid();
    try {
      final dayRef = _daysOf(tripId).doc(dayId);
      final daySnap = await dayRef.get();
      if (!daySnap.exists) {
        throw const NotFoundError(message: 'That day was not found.');
      }
      final day = ItineraryDay.fromMap(daySnap.data()!);
      final newId = _firestore.collection('trips').doc().id;
      final newItem = ItineraryItem(
        id: newId,
        time: item.time,
        title: item.title,
        location: item.location,
        description: item.description,
        emoji: item.emoji,
        type: item.type,
      );
      final items = [...day.items.map((i) => i.toMap()), newItem.toMap()];
      await dayRef.update({'items': items});
      return newItem;
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }
}

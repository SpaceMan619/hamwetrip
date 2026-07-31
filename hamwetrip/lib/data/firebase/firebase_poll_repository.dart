import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../../core/error/app_error.dart';
import '../../data/models/poll.dart';
import '../../domain/repositories/poll_repository.dart';
import 'firebase_error_mapper.dart';

/// Firebase-backed [PollRepository].
///
/// Polls live as a subcollection under each trip:
/// `trips/{tripId}/polls/{pollId}`.
class FirebasePollRepository implements PollRepository {
  FirebasePollRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final fb_auth.FirebaseAuth _auth;

  CollectionReference<Map<String, Object?>> _pollsOf(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('polls');

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const AuthError(message: 'You need to be signed in to do that.');
    }
    return uid;
  }

  @override
  Stream<List<Poll>> watchPolls(String tripId) {
    return _pollsOf(tripId)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => Poll.fromMap(d.id, d.data())).toList(),
        )
        .mapFirebaseErrors();
  }

  @override
  Stream<Poll?> watchPoll(String tripId, String pollId) {
    return _pollsOf(tripId)
        .doc(pollId)
        .snapshots()
        .transform(
          StreamTransformer<
            DocumentSnapshot<Map<String, Object?>>,
            Poll?
          >.fromHandlers(
            handleData: (snap, sink) {
              sink.add(
                snap.exists ? Poll.fromMap(snap.id, snap.data()!) : null,
              );
            },
            handleError: (Object error, StackTrace stackTrace, sink) {
              if (error is FirebaseException &&
                  error.code == 'permission-denied') {
                sink.add(null);
                return;
              }
              sink.addError(mapFirebaseError(error), stackTrace);
            },
          ),
        );
  }

  @override
  Future<Poll> createPoll({
    required String tripId,
    required String question,
    required String category,
    required String categoryEmoji,
    required List<PollOption> options,
    int totalMembers = 0,
    DateTime? deadline,
    bool isActive = true,
    List<String> voterInitials = const [],
    String createdBy = '',
  }) async {
    _requireUid();
    try {
      final ref = _pollsOf(tripId).doc();
      final poll = Poll(
        id: ref.id,
        question: question,
        category: category,
        categoryEmoji: categoryEmoji,
        options: options,
        totalMembers: totalMembers,
        deadline: deadline,
        isActive: isActive,
        voterInitials: voterInitials,
        createdBy: createdBy,
      );
      final data = poll.toMap()..['createdAt'] = FieldValue.serverTimestamp();
      await ref.set(data);
      return poll;
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<void> submitVote({
    required String tripId,
    required String pollId,
    required Set<String> optionIds,
    required String voterInitials,
  }) async {
    _requireUid();
    if (optionIds.isEmpty) {
      throw const InvalidInputError(message: 'Select at least one option.');
    }
    try {
      final ref = _pollsOf(tripId).doc(pollId);
      await _firestore.runTransaction((transaction) async {
        final snap = await transaction.get(ref);
        if (!snap.exists) {
          throw const NotFoundError(message: 'That poll no longer exists.');
        }
        final poll = Poll.fromMap(snap.id, snap.data()!);
        if (!poll.isActive) {
          throw const InvalidInputError(message: 'This poll is closed.');
        }

        // Build updated options with incremented vote counts.
        final updatedOptions = poll.options.map((option) {
          if (optionIds.contains(option.id)) {
            return PollOption(
              id: option.id,
              label: option.label,
              emoji: option.emoji,
              voteCount: option.voteCount + 1,
            );
          }
          return option;
        }).toList();

        // Add voter initials if not already present.
        final updatedVoters = List<String>.from(poll.voterInitials);
        if (!updatedVoters.contains(voterInitials)) {
          updatedVoters.add(voterInitials);
        }

        transaction.update(ref, {
          'options': updatedOptions.map((o) => o.toMap()).toList(),
          'voterInitials': updatedVoters,
        });
      });
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<void> closePoll({
    required String tripId,
    required String pollId,
  }) async {
    _requireUid();
    try {
      await _pollsOf(tripId).doc(pollId).update({'isActive': false});
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }

  @override
  Future<void> deletePoll({
    required String tripId,
    required String pollId,
  }) async {
    _requireUid();
    try {
      await _pollsOf(tripId).doc(pollId).delete();
    } catch (error) {
      throw mapFirebaseError(error);
    }
  }
}

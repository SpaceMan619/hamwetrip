import '../../data/models/poll.dart';

/// Polls for group voting.
///
/// Consumed by the group voting screen and poll results screen.
abstract interface class PollRepository {
  /// All polls for a trip, live-updated.
  ///
  /// Emits immediately (from cache when offline), then live. Emits an empty
  /// list — not an error — when the trip has no polls.
  Stream<List<Poll>> watchPolls(String tripId);

  /// A single poll, live-updated. Emits null if the poll is deleted.
  Stream<Poll?> watchPoll(String tripId, String pollId);

  /// Creates a new poll for the trip.
  Future<Poll> createPoll({
    required String tripId,
    required String question,
    required String category,
    required String categoryEmoji,
    required List<PollOption> options,
    int totalMembers,
    DateTime? deadline,
    bool isActive,
    List<String> voterInitials,
    String createdBy,
  });

  /// Records a vote for one or more options.
  ///
  /// [optionIds] is a set to support multi-choice polls. The repository
  /// increments the voteCount on each selected option and adds the voter's
  /// initials to the poll's voterInitials list.
  Future<void> submitVote({
    required String tripId,
    required String pollId,
    required Set<String> optionIds,
    required String voterInitials,
  });

  /// Closes a poll so no further votes are accepted.
  Future<void> closePoll({required String tripId, required String pollId});

  /// Deletes a poll.
  Future<void> deletePoll({required String tripId, required String pollId});
}

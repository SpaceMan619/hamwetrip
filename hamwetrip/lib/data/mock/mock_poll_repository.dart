import 'dart:async';

import '../../data/models/poll.dart';
import '../../domain/repositories/poll_repository.dart';
import '../../features/shakira/data/demo/mock_polls.dart';

/// In-memory [PollRepository] backed by the existing mock data.
///
/// Used when `useMockRepositories` is true, so the UI can be developed
/// without a reachable Firebase project.
class MockPollRepository implements PollRepository {
  List<Poll> _polls = List.from(mockPolls);
  final _controllers = <StreamController<List<Poll>>>[];

  @override
  Stream<List<Poll>> watchPolls(String tripId) {
    final controller = StreamController<List<Poll>>();
    _controllers.add(controller);
    controller.add(List.from(_polls));
    return controller.stream;
  }

  @override
  Stream<Poll?> watchPoll(String tripId, String pollId) {
    final controller = StreamController<Poll?>();
    controller.add(_polls.where((p) => p.id == pollId).firstOrNull);
    return controller.stream;
  }

  void _notify() {
    for (final c in _controllers) {
      if (!c.isClosed) c.add(List.from(_polls));
    }
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
    final poll = Poll(
      id: 'poll_${DateTime.now().millisecondsSinceEpoch}',
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
    _polls = [..._polls, poll];
    _notify();
    return poll;
  }

  @override
  Future<void> submitVote({
    required String tripId,
    required String pollId,
    required Set<String> optionIds,
    required String voterInitials,
  }) async {
    _polls = _polls.map((poll) {
      if (poll.id != pollId) return poll;
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
      final updatedVoters = List<String>.from(poll.voterInitials);
      if (!updatedVoters.contains(voterInitials)) {
        updatedVoters.add(voterInitials);
      }
      return Poll(
        id: poll.id,
        question: poll.question,
        category: poll.category,
        categoryEmoji: poll.categoryEmoji,
        options: updatedOptions,
        totalMembers: poll.totalMembers,
        deadline: poll.deadline,
        isActive: poll.isActive,
        voterInitials: updatedVoters,
        createdBy: poll.createdBy,
      );
    }).toList();
    _notify();
  }

  @override
  Future<void> closePoll({
    required String tripId,
    required String pollId,
  }) async {
    _polls = _polls
        .map(
          (p) => p.id == pollId
              ? Poll(
                  id: p.id,
                  question: p.question,
                  category: p.category,
                  categoryEmoji: p.categoryEmoji,
                  options: p.options,
                  totalMembers: p.totalMembers,
                  deadline: p.deadline,
                  isActive: false,
                  voterInitials: p.voterInitials,
                  createdBy: p.createdBy,
                )
              : p,
        )
        .toList();
    _notify();
  }

  @override
  Future<void> deletePoll({
    required String tripId,
    required String pollId,
  }) async {
    _polls = _polls.where((p) => p.id != pollId).toList();
    _notify();
  }

  void dispose() {
    for (final c in _controllers) {
      if (!c.isClosed) c.close();
    }
  }
}

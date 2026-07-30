import 'package:flutter/foundation.dart';
import '../../../../../../data/models/poll.dart';
import '../../../data/demo/mock_polls.dart';

class DemoPollState {
  final Poll poll;
  final Set<String> selectedOptionIds;
  final Map<String, int> adjustedVoteCounts;
  final bool isClosed;
  final bool hasVoted;

  const DemoPollState({
    required this.poll,
    required this.selectedOptionIds,
    required this.adjustedVoteCounts,
    this.isClosed = false,
    this.hasVoted = false,
  });

  bool isOptionSelected(String optionId) =>
      selectedOptionIds.contains(optionId);

  int voteCountFor(String optionId) {
    return adjustedVoteCounts[optionId] ??
        poll.options.firstWhere((o) => o.id == optionId).voteCount;
  }

  int get computedTotalVotes =>
      poll.options.fold(0, (sum, o) => sum + voteCountFor(o.id));

  bool get isMultiChoice =>
      poll.question.toLowerCase().contains('select all') ||
      poll.category == 'Activities';

  Poll get displayPoll => Poll(
    id: poll.id,
    question: poll.question,
    category: poll.category,
    categoryEmoji: poll.categoryEmoji,
    options: poll.options
        .map(
          (option) => PollOption(
            id: option.id,
            label: option.label,
            emoji: option.emoji,
            voteCount: voteCountFor(option.id),
          ),
        )
        .toList(growable: false),
    totalMembers: poll.totalMembers,
    deadline: poll.deadline,
    isActive: poll.isActive && !isClosed,
    voterInitials: poll.voterInitials,
    createdBy: poll.createdBy,
  );

  DemoPollState copyWith({
    Set<String>? selectedOptionIds,
    Map<String, int>? adjustedVoteCounts,
    bool? isClosed,
    bool? hasVoted,
  }) {
    return DemoPollState(
      poll: poll,
      selectedOptionIds: selectedOptionIds ?? this.selectedOptionIds,
      adjustedVoteCounts: adjustedVoteCounts ?? this.adjustedVoteCounts,
      isClosed: isClosed ?? this.isClosed,
      hasVoted: hasVoted ?? this.hasVoted,
    );
  }
}

class DemoVotingController extends ChangeNotifier {
  final List<Poll> _sourcePolls = List.from(mockPolls);
  late List<DemoPollState> _states;
  String? _searchQuery;

  DemoVotingController() {
    _states = _sourcePolls
        .map(
          (p) => DemoPollState(
            poll: p,
            selectedOptionIds: {},
            adjustedVoteCounts: {},
          ),
        )
        .toList();
  }

  List<DemoPollState> get polls => _filteredStates;
  int get activePollCount =>
      _states.where((s) => !s.isClosed && s.poll.isActive).length;
  int get closedPollCount =>
      _states.where((s) => s.isClosed || !s.poll.isActive).length;

  List<DemoPollState> get _filteredStates {
    if (_searchQuery == null || _searchQuery!.isEmpty) return _states;
    final q = _searchQuery!.toLowerCase();
    return _states
        .where(
          (s) =>
              s.poll.question.toLowerCase().contains(q) ||
              s.poll.category.toLowerCase().contains(q),
        )
        .toList();
  }

  int _stateIndex(String pollId) =>
      _states.indexWhere((s) => s.poll.id == pollId);

  void selectOption(String pollId, String optionId) {
    final idx = _stateIndex(pollId);
    if (idx == -1) return;
    final state = _states[idx];
    if (state.isClosed || !state.poll.isActive || state.hasVoted) return;

    final newSelected = Set<String>.from(state.selectedOptionIds);

    if (state.isMultiChoice) {
      if (newSelected.contains(optionId)) {
        newSelected.remove(optionId);
      } else {
        newSelected.add(optionId);
      }
    } else {
      newSelected.clear();
      newSelected.add(optionId);
    }

    _states[idx] = state.copyWith(selectedOptionIds: newSelected);
    notifyListeners();
  }

  bool submitVote(String pollId) {
    final idx = _stateIndex(pollId);
    if (idx == -1) return false;
    final state = _states[idx];
    if (state.isClosed ||
        !state.poll.isActive ||
        state.hasVoted ||
        state.selectedOptionIds.isEmpty) {
      return false;
    }

    final newCounts = Map<String, int>.from(state.adjustedVoteCounts);
    for (final optionId in state.selectedOptionIds) {
      final base = state.poll.options
          .firstWhere((option) => option.id == optionId)
          .voteCount;
      newCounts[optionId] = (newCounts[optionId] ?? base) + 1;
    }

    _states[idx] = state.copyWith(
      adjustedVoteCounts: newCounts,
      hasVoted: true,
    );
    notifyListeners();
    return true;
  }

  void closePoll(String pollId) {
    final idx = _stateIndex(pollId);
    if (idx == -1) return;
    _states[idx] = _states[idx].copyWith(isClosed: true);
    notifyListeners();
  }

  void deletePoll(String pollId) {
    _states.removeWhere((s) => s.poll.id == pollId);
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = null;
    notifyListeners();
  }

  double getVotePercentage(String pollId, String optionId) {
    final state = _states.firstWhere((s) => s.poll.id == pollId);
    final total = state.computedTotalVotes;
    if (total == 0) return 0;
    return (state.voteCountFor(optionId) / total) * 100;
  }

  bool hasVoted(String pollId) {
    final state = _states.firstWhere((s) => s.poll.id == pollId);
    return state.hasVoted;
  }

  bool isOptionSelected(String pollId, String optionId) {
    final state = _states.firstWhere((s) => s.poll.id == pollId);
    return state.isOptionSelected(optionId);
  }
}

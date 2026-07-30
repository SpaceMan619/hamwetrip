import 'package:flutter/foundation.dart';
import '../../../../../../data/models/poll.dart';
import '../../../data/demo/mock_polls.dart';

class DemoPollState {
  final Poll poll;
  final Set<String> selectedOptionIds;
  final Map<String, int> adjustedVoteCounts;
  final bool isClosed;

  const DemoPollState({
    required this.poll,
    required this.selectedOptionIds,
    required this.adjustedVoteCounts,
    this.isClosed = false,
  });

  bool get hasVoted => selectedOptionIds.isNotEmpty;
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

  DemoPollState copyWith({
    Set<String>? selectedOptionIds,
    Map<String, int>? adjustedVoteCounts,
    bool? isClosed,
  }) {
    return DemoPollState(
      poll: poll,
      selectedOptionIds: selectedOptionIds ?? this.selectedOptionIds,
      adjustedVoteCounts: adjustedVoteCounts ?? this.adjustedVoteCounts,
      isClosed: isClosed ?? this.isClosed,
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

  void vote(String pollId, String optionId) {
    final idx = _stateIndex(pollId);
    if (idx == -1) return;
    final state = _states[idx];
    if (state.isClosed || !state.poll.isActive) return;

    final newSelected = Set<String>.from(state.selectedOptionIds);
    final newCounts = Map<String, int>.from(state.adjustedVoteCounts);

    if (state.isMultiChoice) {
      if (newSelected.contains(optionId)) {
        newSelected.remove(optionId);
        newCounts[optionId] =
            (newCounts[optionId] ??
                state.poll.options
                    .firstWhere((o) => o.id == optionId)
                    .voteCount) -
            1;
      } else {
        newSelected.add(optionId);
        newCounts[optionId] =
            (newCounts[optionId] ??
                state.poll.options
                    .firstWhere((o) => o.id == optionId)
                    .voteCount) +
            1;
      }
    } else {
      for (final prevId in newSelected) {
        final base = state.poll.options
            .firstWhere((o) => o.id == prevId)
            .voteCount;
        newCounts[prevId] = (newCounts[prevId] ?? base) - 1;
      }
      newSelected.clear();
      newSelected.add(optionId);
      final base = state.poll.options
          .firstWhere((o) => o.id == optionId)
          .voteCount;
      newCounts[optionId] = (newCounts[optionId] ?? base) + 1;
    }

    _states[idx] = state.copyWith(
      selectedOptionIds: newSelected,
      adjustedVoteCounts: newCounts,
    );
    notifyListeners();
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

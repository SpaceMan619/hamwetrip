import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../../../core/error/app_error.dart';
import '../../../../../data/models/poll.dart';
import '../../../../../domain/repositories/poll_repository.dart';

class DemoPollState {
  final Poll poll;
  final Set<String> selectedOptionIds;
  final bool hasVoted;

  const DemoPollState({
    required this.poll,
    required this.selectedOptionIds,
    this.hasVoted = false,
  });

  bool isOptionSelected(String optionId) =>
      selectedOptionIds.contains(optionId);

  int voteCountFor(String optionId) {
    return poll.options.firstWhere((o) => o.id == optionId).voteCount;
  }

  int get computedTotalVotes =>
      poll.options.fold(0, (sum, o) => sum + voteCountFor(o.id));

  bool get isMultiChoice =>
      poll.question.toLowerCase().contains('select all') ||
      poll.category == 'Activities';

  Poll get displayPoll => poll;

  DemoPollState copyWith({Set<String>? selectedOptionIds, bool? hasVoted}) {
    return DemoPollState(
      poll: poll,
      selectedOptionIds: selectedOptionIds ?? this.selectedOptionIds,
      hasVoted: hasVoted ?? this.hasVoted,
    );
  }
}

class DemoVotingController extends ChangeNotifier {
  final PollRepository _repository;
  final String tripId;
  final String voterInitials;

  List<DemoPollState> _states = [];
  bool _isLoading = true;
  AppError? _error;
  String? _searchQuery;
  StreamSubscription<List<Poll>>? _subscription;

  DemoVotingController({
    required PollRepository repository,
    this.tripId = 'demo-trip',
    this.voterInitials = 'ME',
  }) : _repository = repository {
    _loadPolls();
  }

  // ──────────────────────────────────────────────
  // Loading & error state
  // ──────────────────────────────────────────────

  bool get isLoading => _isLoading;
  AppError? get error => _error;
  bool get hasError => _error != null;

  // ──────────────────────────────────────────────
  // Data accessors
  // ──────────────────────────────────────────────

  List<DemoPollState> get polls => _filteredStates;
  int get activePollCount =>
      _states.where((s) => s.poll.isActive && !s.hasVoted).length;
  int get closedPollCount =>
      _states.where((s) => !s.poll.isActive || s.hasVoted).length;

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

  // ──────────────────────────────────────────────
  // Stream subscription
  // ──────────────────────────────────────────────

  void _loadPolls() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _subscription = _repository
        .watchPolls(tripId)
        .listen(
          (polls) {
            _isLoading = false;
            _error = null;
            // Preserve local selection/voted state across stream updates.
            final previousStates = {for (final s in _states) s.poll.id: s};
            _states = polls.map((p) {
              final prev = previousStates[p.id];
              return DemoPollState(
                poll: p,
                selectedOptionIds: prev?.selectedOptionIds ?? {},
                hasVoted: prev?.hasVoted ?? false,
              );
            }).toList();
            notifyListeners();
          },
          onError: (Object error) {
            _isLoading = false;
            _error = error is AppError
                ? error
                : const UnknownError(message: 'Failed to load polls.');
            notifyListeners();
          },
        );
  }

  Future<void> retry() async {
    await _subscription?.cancel();
    _loadPolls();
  }

  // ──────────────────────────────────────────────
  // Actions
  // ──────────────────────────────────────────────

  void selectOption(String pollId, String optionId) {
    final idx = _stateIndex(pollId);
    if (idx == -1) return;
    final state = _states[idx];
    if (!state.poll.isActive || state.hasVoted) return;

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

  Future<bool> submitVote(String pollId) async {
    final idx = _stateIndex(pollId);
    if (idx == -1) return false;
    final state = _states[idx];
    if (!state.poll.isActive ||
        state.hasVoted ||
        state.selectedOptionIds.isEmpty) {
      return false;
    }

    // Set hasVoted BEFORE the repository call, because the repository
    // may emit a stream event that triggers _loadPolls' listener, which
    // rebuilds _states. Setting it first ensures the listener preserves it.
    _states[idx] = state.copyWith(hasVoted: true);
    notifyListeners();

    try {
      await _repository.submitVote(
        tripId: tripId,
        pollId: pollId,
        optionIds: state.selectedOptionIds,
        voterInitials: voterInitials,
      );
      return true;
    } on AppError catch (e) {
      _error = e;
      notifyListeners();
      return false;
    } catch (e) {
      _error = UnknownError(cause: e);
      notifyListeners();
      return false;
    }
  }

  Future<void> closePoll(String pollId) async {
    try {
      await _repository.closePoll(tripId: tripId, pollId: pollId);
    } on AppError catch (e) {
      _error = e;
      notifyListeners();
    } catch (e) {
      _error = UnknownError(cause: e);
      notifyListeners();
    }
  }

  Future<void> deletePoll(String pollId) async {
    try {
      await _repository.deletePoll(tripId: tripId, pollId: pollId);
    } on AppError catch (e) {
      _error = e;
      notifyListeners();
    } catch (e) {
      _error = UnknownError(cause: e);
      notifyListeners();
    }
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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

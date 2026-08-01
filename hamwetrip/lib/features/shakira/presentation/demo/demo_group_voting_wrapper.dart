import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../app/app_routes.dart';
import '../group_voting_screen.dart';
import 'controllers/demo_voting_controller.dart';
import '../../../../core/state/view_state.dart';
import '../../../../core/widgets/create_forms.dart';
import '../../../../core/widgets/hamwe_bottom_navigation.dart';
import '../../../../core/widgets/trip_scoped.dart';
import '../../../trips/trip_providers.dart';

class DemoGroupVotingWrapper extends StatelessWidget {
  const DemoGroupVotingWrapper({super.key});

  @override
  Widget build(BuildContext context) => TripScoped(
    destination: HamweDestination.trips,
    builder: (tripId) =>
        _GroupVotingView(key: ValueKey(tripId), tripId: tripId),
  );
}

class _GroupVotingView extends ConsumerStatefulWidget {
  const _GroupVotingView({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<_GroupVotingView> createState() =>
      _DemoGroupVotingWrapperState();
}

class _DemoGroupVotingWrapperState extends ConsumerState<_GroupVotingView> {
  late final DemoVotingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DemoVotingController(
      repository: ref.read(pollRepositoryProvider),
      tripId: widget.tripId,
      voterInitials: 'ME',
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _createPoll() async {
    final input = await showCreatePollForm(context);
    if (input == null || !mounted) return;

    // The roster gives the denominator the poll card shows as "x of y voted".
    final membersState = ref.read(tripMembersControllerProvider(widget.tripId));
    final memberCount = switch (membersState.view) {
      ViewData(:final data) => data.length,
      _ => 0,
    };

    final created = await _controller.createPoll(
      question: input.question,
      optionLabels: input.options,
      totalMembers: memberCount,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          created
              ? 'Poll created'
              : _controller.error?.message ?? 'Could not create the poll',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: created ? AppColors.forest : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_controller.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.warmSand,
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: const HamweBottomNavigation(
          selected: HamweDestination.trips,
        ),
      );
    }

    // Error state
    if (_controller.hasError) {
      return Scaffold(
        backgroundColor: AppColors.warmSand,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _controller.error?.message ?? 'Something went wrong',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _controller.retry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const HamweBottomNavigation(
          selected: HamweDestination.trips,
        ),
      );
    }

    final activePolls = _controller.polls
        .where((s) => s.poll.isActive && !s.hasVoted)
        .map((s) => s.displayPoll)
        .toList();

    final closedPolls = _controller.polls
        .where((s) => !s.poll.isActive || s.hasVoted)
        .map((s) => s.displayPoll)
        .toList();

    final selectedIds = {
      for (final state in _controller.polls)
        state.poll.id: Set<String>.unmodifiable(state.selectedOptionIds),
    };
    final votedPollIds = {
      for (final state in _controller.polls)
        if (state.hasVoted) state.poll.id,
    };

    return GroupVotingScreen(
      activePolls: activePolls,
      closedPolls: closedPolls,
      selectedOptionIds: selectedIds,
      votedPollIds: votedPollIds,
      bottomNavigation: const HamweBottomNavigation(
        selected: HamweDestination.trips,
      ),
      onOptionTap: (pollId, optId) {
        _controller.selectOption(pollId, optId);
      },
      onVote: (pollId) async {
        final success = await _controller.submitVote(pollId);
        if (!context.mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vote recorded successfully!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.forest,
            ),
          );
        } else if (_controller.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _controller.error?.message ?? 'Failed to submit vote',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select an option first'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      onClosePoll: (pollId) async {
        await _controller.closePoll(pollId);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _controller.hasError
                  ? _controller.error?.message ?? 'Failed to close poll'
                  : 'Poll closed',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onCreatePoll: _createPoll,
      onViewResults: (poll) {
        Navigator.of(context).pushNamed(AppRoutes.pollResults, arguments: poll);
      },
    );
  }
}

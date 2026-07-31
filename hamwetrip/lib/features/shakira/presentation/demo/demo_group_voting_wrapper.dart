import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../app/app_routes.dart';
import '../group_voting_screen.dart';
import 'controllers/demo_voting_controller.dart';
import '../../../../core/widgets/hamwe_bottom_navigation.dart';

class DemoGroupVotingWrapper extends ConsumerStatefulWidget {
  const DemoGroupVotingWrapper({super.key});

  @override
  ConsumerState<DemoGroupVotingWrapper> createState() =>
      _DemoGroupVotingWrapperState();
}

class _DemoGroupVotingWrapperState
    extends ConsumerState<DemoGroupVotingWrapper> {
  late final DemoVotingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DemoVotingController(
      repository: ref.read(pollRepositoryProvider),
      voterInitials: 'ME',
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_controller.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.warmSand,
        body: Center(child: CircularProgressIndicator()),
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
      onCreatePoll: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Create poll form coming soon'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onViewResults: (poll) {
        Navigator.of(context).pushNamed(AppRoutes.pollResults, arguments: poll);
      },
    );
  }
}

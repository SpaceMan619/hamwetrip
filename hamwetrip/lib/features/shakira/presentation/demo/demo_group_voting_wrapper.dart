import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../app/app_routes.dart';
import '../group_voting_screen.dart';
import 'controllers/demo_voting_controller.dart';
import '../../../../../core/widgets/hamwe_bottom_navigation.dart';

class DemoGroupVotingWrapper extends StatefulWidget {
  const DemoGroupVotingWrapper({super.key});

  @override
  State<DemoGroupVotingWrapper> createState() => _DemoGroupVotingWrapperState();
}

class _DemoGroupVotingWrapperState extends State<DemoGroupVotingWrapper> {
  late final DemoVotingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DemoVotingController();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // connect the demo voting controller to the voting screen.
    final activePolls = _controller.polls
        .where((s) => !s.isClosed && s.poll.isActive)
        .map((s) => s.displayPoll)
        .toList();

    final closedPolls = _controller.polls
        .where((s) => s.isClosed || !s.poll.isActive)
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
      onVote: (pollId) {
        if (_controller.submitVote(pollId)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vote recorded successfully! (Demo)'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.forest,
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
      onClosePoll: (pollId) {
        _controller.closePoll(pollId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Poll closed (Demo)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onCreatePoll: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Create poll will be available after backend integration',
            ),
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

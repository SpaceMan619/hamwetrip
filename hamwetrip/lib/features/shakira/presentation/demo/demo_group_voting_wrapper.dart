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
    final activePolls = _controller.polls
        .where((s) => !s.isClosed && s.poll.isActive)
        .map((s) => s.poll)
        .toList();

    final closedPolls = _controller.polls
        .where((s) => s.isClosed || !s.poll.isActive)
        .map((s) => s.poll)
        .toList();

    // Extract the last clicked option ID from the Set to satisfy PollCard
    final Map<String, String?> selectedIds = {};
    for (final state in _controller.polls) {
      if (state.selectedOptionIds.isNotEmpty) {
        selectedIds[state.poll.id] = state.selectedOptionIds.last;
      } else {
        selectedIds[state.poll.id] = null;
      }
    }

    return GroupVotingScreen(
      activePolls: activePolls,
      closedPolls: closedPolls,
      selectedOptionIds: selectedIds,
      bottomNavigation: const HamweBottomNavigation(
        selected: HamweDestination.ledger,
      ),
      onOptionTap: (pollId, optId) {
        _controller.vote(pollId, optId);
      },
      onVote: (pollId) {
        if (_controller.hasVoted(pollId)) {
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

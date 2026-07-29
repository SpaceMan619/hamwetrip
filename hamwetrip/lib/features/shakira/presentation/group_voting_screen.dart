import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/poll.dart';
import '../../../core/widgets/shakira_widgets/poll_card.dart';

class GroupVotingScreen extends StatelessWidget {
  final List<Poll> activePolls;
  final List<Poll> closedPolls;
  final void Function(String, String) onOptionTap;
  final void Function(String) onVote;
  final void Function(String) onClosePoll;
  final VoidCallback onCreatePoll;
  final void Function(Poll) onViewResults;
  final Widget? bottomNavigation;

  const GroupVotingScreen({
    super.key,
    required this.activePolls,
    required this.closedPolls,
    required this.onOptionTap,
    required this.onVote,
    required this.onClosePoll,
    required this.onCreatePoll,
    required this.onViewResults,
    this.bottomNavigation,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.warmSand,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Text('Group Voting'),
          actions: [
            IconButton(
              onPressed: onCreatePoll,
              icon: const Icon(
                Icons.add_circle_outline,
                color: AppColors.forest,
              ),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.forest,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
            unselectedLabelStyle: TextStyle(color: AppColors.muted),
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Closed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PollListView(
              polls: activePolls,
              onOptionTap: onOptionTap,
              onVote: onVote,
              onClosePoll: onClosePoll,
              onViewResults: onViewResults,
            ),
            _PollListView(
              polls: closedPolls,
              onOptionTap: onOptionTap,
              onVote: onVote,
              onClosePoll: onClosePoll,
              onViewResults: onViewResults,
            ),
          ],
        ),
        bottomNavigationBar: bottomNavigation,
        floatingActionButton: FloatingActionButton(
          onPressed: onCreatePoll,
          backgroundColor: AppColors.forest,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

class _PollListView extends StatelessWidget {
  final List<Poll> polls;
  final void Function(String, String) onOptionTap;
  final void Function(String) onVote;
  final void Function(String) onClosePoll;
  final void Function(Poll) onViewResults;

  const _PollListView({
    required this.polls,
    required this.onOptionTap,
    required this.onVote,
    required this.onClosePoll,
    required this.onViewResults,
  });

  @override
  Widget build(BuildContext context) {
    if (polls.isEmpty) {
      return const Center(
        child: Text('No polls here', style: TextStyle(color: AppColors.muted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: polls.length,
      itemBuilder: (context, index) {
        final poll = polls[index];
        return PollCard(
          poll: poll,
          onTap: !poll.isActive ? () => onViewResults(poll) : null,
          onOptionTap: (optId) => onOptionTap(poll.id, optId),
          onVote: () => onVote(poll.id),
          onClosePoll: () => onClosePoll(poll.id),
        );
      },
    );
  }
}

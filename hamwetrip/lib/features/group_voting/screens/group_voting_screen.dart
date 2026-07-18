import 'package:flutter/material.dart';
import '../models/poll.dart';
import '../widgets/poll_card.dart';
import 'poll_results_screen.dart'; // Imported to enable navigation

class GroupVotingScreen extends StatefulWidget {
  const GroupVotingScreen({super.key});

  @override
  State<GroupVotingScreen> createState() => _GroupVotingScreenState();
}

class _GroupVotingScreenState extends State<GroupVotingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final Map<String, String?> _selectedOptions = {};
  final Map<String, String> _confirmedVotes = {};

  final List<Poll> _polls = const [
    Poll(
      id: 'poll_1',
      question: 'Where should we have dinner on Friday night?',
      category: 'Restaurant',
      categoryEmoji: '🍽️',
      options: [
        PollOption(
          id: 'opt_1a',
          label: 'Heaven Restaurant',
          emoji: '🍽️',
          voteCount: 6,
        ),
        PollOption(
          id: 'opt_1b',
          label: 'Revo Ethiopian Restaurant',
          emoji: '🥘',
          voteCount: 2,
        ),
      ],
      totalMembers: 12,
      deadline: null,
      isActive: true,
      voterInitials: ['JK', 'AM', 'CN', 'PD', 'SK', 'LM', 'RT', 'BG'],
      createdBy: 'Jean Pierre',
    ),
    Poll(
      id: 'poll_2',
      question: 'Which activity for Saturday morning?',
      category: 'Activity',
      categoryEmoji: '🎯',
      options: [
        PollOption(
          id: 'opt_2a',
          label: 'Gorilla Trekking',
          emoji: '🦍',
          voteCount: 5,
        ),
        PollOption(
          id: 'opt_2b',
          label: 'Lake Kivu Boat Tour',
          emoji: '🚤',
          voteCount: 3,
        ),
        PollOption(
          id: 'opt_2c',
          label: 'Nyungwe Canopy Walk',
          emoji: '🌿',
          voteCount: 2,
        ),
      ],
      totalMembers: 12,
      deadline: null,
      isActive: true,
      voterInitials: [
        'JK',
        'AM',
        'CN',
        'PD',
        'SK',
        'LM',
        'RT',
        'BG',
        'HN',
        'YW',
      ],
      createdBy: 'Alice Mugisha',
    ),
    Poll(
      id: 'poll_3',
      question: 'Transport option for airport transfer?',
      category: 'Transport',
      categoryEmoji: '🚗',
      options: [
        PollOption(
          id: 'opt_3a',
          label: 'Shared Shuttle',
          emoji: '🚐',
          voteCount: 7,
        ),
        PollOption(
          id: 'opt_3b',
          label: 'Private Car',
          emoji: '🚗',
          voteCount: 3,
        ),
        PollOption(
          id: 'opt_3c',
          label: 'Motorcycle Taxi',
          emoji: '🏍️',
          voteCount: 1,
        ),
      ],
      totalMembers: 12,
      deadline: null,
      isActive: true,
      voterInitials: [
        'JK',
        'AM',
        'CN',
        'PD',
        'SK',
        'LM',
        'RT',
        'BG',
        'HN',
        'YW',
        'ED',
      ],
      createdBy: 'Claude Niyonsaba',
    ),
    Poll(
      id: 'poll_4',
      question: 'Where to stay in Musanze?',
      category: 'Accommodation',
      categoryEmoji: '🏨',
      options: [
        PollOption(
          id: 'opt_4a',
          label: 'Five Volcanoes Boutique Hotel',
          emoji: '🏔️',
          voteCount: 9,
        ),
        PollOption(
          id: 'opt_4b',
          label: 'Kinigi Guest House',
          emoji: '🏡',
          voteCount: 3,
        ),
      ],
      totalMembers: 12,
      deadline: null,
      isActive: false,
      voterInitials: [
        'JK',
        'AM',
        'CN',
        'PD',
        'SK',
        'LM',
        'RT',
        'BG',
        'HN',
        'YW',
        'ED',
        'FG',
      ],
      createdBy: 'Sarah Kim',
    ),
  ];

  List<Poll> get _pollsWithDeadlines {
    final now = DateTime.now();
    return _polls.map((p) {
      if (p.isActive && p.deadline == null) {
        final hours = [2, 5, 24][_polls.indexOf(p) % 3];
        return Poll(
          id: p.id,
          question: p.question,
          category: p.category,
          categoryEmoji: p.categoryEmoji,
          options: p.options,
          totalMembers: p.totalMembers,
          deadline: now.add(Duration(hours: hours)),
          isActive: p.isActive,
          voterInitials: p.voterInitials,
          createdBy: p.createdBy,
        );
      }
      return p;
    }).toList();
  }

  List<Poll> get _activePolls =>
      _pollsWithDeadlines.where((p) => p.isActive).toList();
  List<Poll> get _closedPolls =>
      _pollsWithDeadlines.where((p) => !p.isActive).toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleOptionTap(String pollId, String optionId) {
    setState(() => _selectedOptions[pollId] = optionId);
  }

  void _handleVote(String pollId) {
    final optionId = _selectedOptions[pollId];
    if (optionId == null) return;
    debugPrint('Vote submitted → poll: $pollId, option: $optionId');
    setState(() {
      _confirmedVotes[pollId] = optionId;
      _selectedOptions.remove(pollId);
    });
  }

  void _handleClosePoll(String pollId) {
    debugPrint('Close poll requested → $pollId');
  }

  void _handleCreatePoll() {
    debugPrint('Create new poll tapped');
  }

  // ADDED: Navigation to Results Screen
  void _handleViewResults(Poll poll) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => PollResultsScreen(poll: poll)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width > 600;
    final horizontalPadding = isTablet ? 32.0 : 16.0;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        title: const Text('Group Voting'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search_outlined),
            tooltip: 'Search polls',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 18,
            ),
            color: colorScheme.surface,
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.how_to_vote_outlined,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kigali City Tour',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_activePolls.length} active polls  ·  12 members',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _handleCreatePoll,
                  icon: const Icon(Icons.add, size: 20),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(40, 40),
                    maximumSize: const Size(40, 40),
                    padding: EdgeInsets.zero,
                  ),
                  tooltip: 'New Poll',
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withOpacity(0.4),
          ),
          Container(
            color: colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              dividerColor: colorScheme.outlineVariant.withOpacity(0.4),
              tabs: [
                _CountTab(
                  label: 'Active',
                  count: _activePolls.length,
                  isActive: true,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
                _CountTab(
                  label: 'Closed',
                  count: _closedPolls.length,
                  isActive: false,
                  colorScheme: colorScheme,
                  theme: theme,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PollListView(
                  polls: _activePolls,
                  padding: horizontalPadding,
                  selectedOptions: _selectedOptions,
                  confirmedVotes: _confirmedVotes,
                  onOptionTap: _handleOptionTap,
                  onVote: _handleVote,
                  onClosePoll: _handleClosePoll,
                  onViewResults: _handleViewResults, // ADDED
                ),
                _PollListView(
                  polls: _closedPolls,
                  padding: horizontalPadding,
                  selectedOptions: _selectedOptions,
                  confirmedVotes: _confirmedVotes,
                  onOptionTap: _handleOptionTap,
                  onVote: _handleVote,
                  onClosePoll: _handleClosePoll,
                  onViewResults: _handleViewResults, // ADDED
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: isTablet
          ? null
          : FloatingActionButton.extended(
              onPressed: _handleCreatePoll,
              icon: const Icon(Icons.add),
              label: const Text('New Poll'),
            ),
    );
  }
}

class _CountTab extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _CountTab({
    required this.label,
    required this.count,
    required this.isActive,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isActive
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PollListView extends StatelessWidget {
  final List<Poll> polls;
  final double padding;
  final Map<String, String?> selectedOptions;
  final Map<String, String> confirmedVotes;
  final void Function(String, String) onOptionTap;
  final void Function(String) onVote;
  final void Function(String) onClosePoll;
  final void Function(Poll) onViewResults; // ADDED

  const _PollListView({
    required this.polls,
    required this.padding,
    required this.selectedOptions,
    required this.confirmedVotes,
    required this.onOptionTap,
    required this.onVote,
    required this.onClosePoll,
    required this.onViewResults, // ADDED
  });

  @override
  Widget build(BuildContext context) {
    if (polls.isEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.poll_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.35),
            ),
            const SizedBox(height: 16),
            Text(
              'No polls here',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
      itemCount: polls.length,
      itemBuilder: (context, index) {
        final poll = polls[index];
        final hasVoted = confirmedVotes.containsKey(poll.id);
        final selectedOptionId = hasVoted
            ? confirmedVotes[poll.id]
            : selectedOptions[poll.id];

        return PollCard(
          poll: poll,
          selectedOptionId: selectedOptionId,
          hasVoted: hasVoted,
          onVote: () => onVote(poll.id),
          onOptionTap: (optionId) => onOptionTap(poll.id, optionId),
          onClosePoll: poll.isActive ? () => onClosePoll(poll.id) : null,
          // ADDED: If user has voted OR poll is closed, tapping navigates to results
          onTap: (hasVoted || !poll.isActive)
              ? () => onViewResults(poll)
              : null,
        );
      },
    );
  }
}

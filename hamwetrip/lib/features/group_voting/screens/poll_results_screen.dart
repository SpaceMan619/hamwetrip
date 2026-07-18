import 'package:flutter/material.dart';
import '../models/poll.dart';
import '../widgets/avatar_stack.dart';
import '../widgets/winner_card.dart';
import '../widgets/result_option_bar.dart';

class PollResultsScreen extends StatefulWidget {
  final Poll poll;

  const PollResultsScreen({super.key, required this.poll});

  @override
  State<PollResultsScreen> createState() => _PollResultsScreenState();
}

class _PollResultsScreenState extends State<PollResultsScreen> {
  bool _animateBars = false;

  // Mock voter mapping for the breakdown section
  final Map<String, List<String>> _voterMap = const {
    'opt_1a': ['JK', 'AM', 'CN', 'PD', 'SK', 'LM'],
    'opt_1b': ['RT', 'BG'],
    'opt_1c': ['HN', 'YW', 'ED'],
  };

  PollOption get _winner {
    final sortedOptions = List<PollOption>.from(widget.poll.options)
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));
    return sortedOptions.first;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _animateBars = true);
    });
  }

  void _handleShareResults() {
    debugPrint('Share results tapped');
  }

  void _handleCreateSimilar() {
    debugPrint('Create similar poll tapped');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width > 600;
    final horizontalPadding = isTablet ? 40.0 : 20.0;
    final maxWidth = isTablet ? 600.0 : double.infinity;

    // FIX: Sort options cleanly into a local variable before building the UI
    final sortedOptions = List<PollOption>.from(widget.poll.options)
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Poll Results'),
        actions: [
          IconButton(
            onPressed: _handleShareResults,
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Results',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.poll.categoryEmoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.poll.category,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.poll.question,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Created by ${widget.poll.createdBy}  ·  ${widget.poll.totalVotes} total votes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),

                WinnerCard(poll: widget.poll, winner: _winner),
                const SizedBox(height: 32),

                Text(
                  'Full Breakdown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                // FIX: Safely map over the sorted local list
                ...sortedOptions.map((option) {
                  return ResultOptionBar(
                    option: option,
                    totalVotes: widget.poll.totalVotes,
                    isWinner: option.id == _winner.id,
                    animate: _animateBars,
                  );
                }),

                const SizedBox(height: 32),
                Text(
                  'Who voted for what?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                ...widget.poll.options.map((option) {
                  final voters = _voterMap[option.id] ?? [];
                  if (voters.isEmpty) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (option.emoji != null) ...[
                              Text(
                                option.emoji!,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              option.label,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AvatarStack(initials: voters, size: 28, maxVisible: 5),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: _handleCreateSimilar,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Create Similar Poll'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

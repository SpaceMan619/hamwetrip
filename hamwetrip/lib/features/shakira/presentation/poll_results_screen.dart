import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/poll.dart';
import '../../../core/widgets/shakira_widgets/result_option_bar.dart';
import '../../../core/widgets/shakira_widgets/winner_card.dart';

class PollResultsScreen extends StatelessWidget {
  final Poll poll;
  final Map<String, String>
  voterChoices; // Dynamic data instead of hardcoded chips
  final VoidCallback onShareResults;
  final VoidCallback onAddToItinerary;

  const PollResultsScreen({
    super.key,
    required this.poll,
    required this.voterChoices,
    required this.onShareResults,
    required this.onAddToItinerary,
  });

  PollOption get _winner {
    final sorted = List<PollOption>.from(poll.options)
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));
    return sorted.first;
  }

  @override
  Widget build(BuildContext context) {
    final sortedOptions = List<PollOption>.from(poll.options)
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));

    return Scaffold(
      backgroundColor: AppColors.warmSand,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.ink,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Poll Results'),
        actions: [
          IconButton(
            onPressed: onShareResults,
            icon: const Icon(Icons.share_outlined, color: AppColors.forest),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poll.question,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Created by ${poll.createdBy}  ·  ${poll.totalVotes} total votes',
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 28),

            // Winner Card
            WinnerCard(poll: poll, winner: _winner),
            const SizedBox(height: 32),

            // Full Breakdown
            const Text(
              'Full Breakdown',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedOptions.map(
              (option) => ResultOptionBar(
                option: option,
                totalVotes: poll.totalVotes,
                isWinner: option.id == _winner.id,
                animate: true,
              ),
            ),
            const SizedBox(height: 40),

            // Who Voted Section (Now dynamically generated!)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Who voted',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: voterChoices.entries
                  .map((e) => _VoterChip(initials: e.key, choice: e.value))
                  .toList(),
            ),

            const SizedBox(height: 40),

            // Add to Itinerary Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onAddToItinerary,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Add to Itinerary'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Widget to display a voter and their choice
class _VoterChip extends StatelessWidget {
  final String initials;
  final String choice;

  const _VoterChip({required this.initials, required this.choice});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warmSand,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.forest,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            choice,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/poll.dart';
import '../../../core/widgets/shakira_widgets/result_option_bar.dart';
import '../../../core/widgets/shakira_widgets/winner_card.dart';

class PollResultsScreen extends StatelessWidget {
  final Poll poll;
  final VoidCallback onShareResults;
  final VoidCallback onCreateSimilar;

  const PollResultsScreen({
    super.key,
    required this.poll,
    required this.onShareResults,
    required this.onCreateSimilar,
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
            WinnerCard(poll: poll, winner: _winner),
            const SizedBox(height: 32),
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
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: onCreateSimilar,
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
    );
  }
}

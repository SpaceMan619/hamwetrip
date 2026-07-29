import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/poll.dart';
import '../poll_results_screen.dart';

/// Wires up mock voter data to your pure UI screen.
/// This screen is navigated to with a Poll argument from the Voting screen.
class DemoPollResultsWrapper extends StatelessWidget {
  const DemoPollResultsWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Grab the Poll passed from the Group Voting Screen
    final poll = ModalRoute.of(context)?.settings.arguments as Poll?;

    if (poll == null) {
      return const Scaffold(
        body: Center(
          child: Text('Poll not found. Please open from the Voting screen.'),
        ),
      );
    }

    // 2. Dynamically generate the voter map from the poll's voterInitials
    // (In production, the backend would return exactly who voted for what)
    final Map<String, String> voterChoices = {};
    if (poll.options.isNotEmpty) {
      // For the demo, we pretend everyone voted for the first (winning) option
      for (final initial in poll.voterInitials) {
        voterChoices[initial] = poll.options.first.label;
      }
    }

    return PollResultsScreen(
      poll: poll,
      voterChoices: voterChoices,

      // Fixes "Empty Handler" - Share button
      onShareResults: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Poll results link copied to clipboard! (Simulated)'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.forest,
          ),
        );
      },

      // Fixes "Empty Handler" - Add to Itinerary button
      onAddToItinerary: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"${poll.options.first.label}" added to Day 1 itinerary! (Demo)',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.forest,
          ),
        );

        // Optional: Navigate back to the itinerary screen
        // Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.detailedItinerary, (route) => route.isFirst);
      },
    );
  }
}

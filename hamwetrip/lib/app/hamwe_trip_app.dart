import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/rajveer/presentation/rajveer_screens.dart';
import 'app_routes.dart';

// ✅ ADD THESE IMPORTS FOR THE NEW WRAPPERS
import '../features/shakira/presentation/demo/demo_detailed_itinerary_wrapper.dart';
import '../features/shakira/presentation/demo/demo_document_vault_wrapper.dart';
import '../features/shakira/presentation/demo/demo_expense_splitting_wrapper.dart';
import '../features/shakira/presentation/demo/demo_group_voting_wrapper.dart';
import '../features/shakira/presentation/demo/demo_momo_summary_wrapper.dart';
import '../features/shakira/presentation/demo/demo_poll_results_wrapper.dart';
import '../features/shakira/presentation/demo/demo_settlement_confirmation_wrapper.dart';

class HamweTripApp extends StatelessWidget {
  const HamweTripApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HamweTrip',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.onboarding: (_) => const OnboardingScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.dashboard: (_) => const TripDashboardScreen(),
        AppRoutes.createTrip: (_) => const CreateTripScreen(),
        AppRoutes.inviteMembers: (_) => const InviteMembersScreen(),
        AppRoutes.activityFeed: (_) => const ActivityFeedScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),

        // --- New Shakira Demo Routes ---
        AppRoutes.detailedItinerary: (_) =>
            const DemoDetailedItineraryWrapper(),
        AppRoutes.documentVault: (_) => const DemoDocumentVaultWrapper(),
        AppRoutes.expenseSplitting: (_) => const DemoExpenseSplittingWrapper(),
        AppRoutes.groupVoting: (_) => const DemoGroupVotingWrapper(),
        AppRoutes.momoSummary: (_) => const DemoMomoSummaryWrapper(),
        AppRoutes.pollResults: (_) => const DemoPollResultsWrapper(),
        AppRoutes.settlementConfirmation: (_) =>
            const DemoSettlementConfirmationWrapper(),
      },
    );
  }
}

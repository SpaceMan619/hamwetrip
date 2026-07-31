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
    // set up the shared app shell and route table.
    return MaterialApp(
      title: 'HamweTrip',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.home,
      onGenerateRoute: _routeFor,
    );
  }

  // Top-level destinations behave like a workspace switch: no misleading
  // horizontal page slide when the floating navigation pill is used.
  static Route<dynamic> _routeFor(RouteSettings settings) {
    // build each screen without a slide when switching destinations.
    final Widget page = switch (settings.name) {
      AppRoutes.home => const HomeScreen(),
      AppRoutes.onboarding => const OnboardingScreen(),
      AppRoutes.login => const LoginScreen(),
      AppRoutes.dashboard => const TripDashboardScreen(),
      AppRoutes.createTrip => const CreateTripScreen(),
      AppRoutes.inviteMembers => const InviteMembersScreen(),
      AppRoutes.activityFeed => const ActivityFeedScreen(),
      AppRoutes.profile => const ProfileScreen(),
      AppRoutes.detailedItinerary => const DemoDetailedItineraryWrapper(),
      AppRoutes.documentVault => const DemoDocumentVaultWrapper(),
      AppRoutes.expenseSplitting => const DemoExpenseSplittingWrapper(),
      AppRoutes.groupVoting => const DemoGroupVotingWrapper(),
      AppRoutes.momoSummary => const DemoMomoSummaryWrapper(),
      AppRoutes.pollResults => const DemoPollResultsWrapper(),
      AppRoutes.settlementConfirmation =>
        const DemoSettlementConfirmationWrapper(),
      _ => const HomeScreen(),
    };

    return PageRouteBuilder<void>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}

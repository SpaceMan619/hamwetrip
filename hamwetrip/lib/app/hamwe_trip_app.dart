import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/rajveer/presentation/rajveer_screens.dart';
import 'app_routes.dart';

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
      },
    );
  }
}

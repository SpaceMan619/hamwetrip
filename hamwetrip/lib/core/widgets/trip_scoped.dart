import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/home_providers.dart';
import '../preferences/app_preferences.dart';
import '../state/view_state.dart';
import '../theme/app_colors.dart';
import 'hamwe_bottom_navigation.dart';

/// Resolves which trip a trip-scoped screen should show, then builds it.
///
/// The voting, expense, MoMo, itinerary and vault screens all live inside a
/// trip but are reached from the bottom navigation, which carries no arguments.
/// They previously fell back to a hardcoded `'demo-trip'`, which no account is
/// a member of, so every read was refused by the security rules.
///
/// The trip is taken from, in order: the route arguments, the trip this device
/// last opened, and failing both the caller's most recent trip. Somebody with
/// no trips at all sees an invitation to make one rather than an error.
///
/// Every state it can show keeps the bottom navigation, including while
/// loading and when there is no trip. Without it a member who reaches one of
/// these screens before creating a trip is stranded on a screen with nothing
/// to tap.
class TripScoped extends ConsumerWidget {
  const TripScoped({
    super.key,
    required this.destination,
    required this.builder,
  });

  /// Which tab to light up in the states this widget renders itself. The
  /// screen built by [builder] supplies its own.
  final HamweDestination destination;

  /// Built once a trip is known. Give the returned widget a `ValueKey(tripId)`
  /// so its state is rebuilt from scratch when the trip changes.
  final Widget Function(String tripId) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeTripId = ModalRoute.of(context)?.settings.arguments as String?;
    if (routeTripId != null) return builder(routeTripId);

    final remembered = ref.read(appPreferencesProvider).lastOpenedTripId;
    final tripsState = ref.watch(myTripsControllerProvider);

    return switch (tripsState.view) {
      ViewLoading() => _TripScopedScaffold(
        destination: destination,
        child: const Center(child: CircularProgressIndicator()),
      ),
      ViewData(:final data) when data.isNotEmpty => builder(
        data
            .firstWhere(
              (trip) => trip.id == remembered,
              orElse: () => data.first,
            )
            .id,
      ),
      ViewError(:final error) => _TripScopedMessage(
        destination: destination,
        icon: Icons.error_outline,
        message: error.message,
      ),
      // Empty, or data that turned out to hold no trips.
      _ => _TripScopedMessage(
        destination: destination,
        icon: Icons.luggage_outlined,
        message: 'Create or join a trip first, then come back to this screen.',
      ),
    };
  }
}

/// The shell these states share: the app's bottom navigation, so there is
/// always a way off the screen.
class _TripScopedScaffold extends StatelessWidget {
  const _TripScopedScaffold({required this.destination, required this.child});

  final HamweDestination destination;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmSand,
      // Shown only when this screen was pushed onto something. Reached from the
      // bottom navigation there is nothing to pop, and an inert arrow would be
      // worse than none.
      appBar: Navigator.of(context).canPop()
          ? AppBar(
              backgroundColor: AppColors.warmSand,
              elevation: 0,
              foregroundColor: AppColors.forest,
            )
          : null,
      body: child,
      bottomNavigationBar: HamweBottomNavigation(selected: destination),
    );
  }
}

class _TripScopedMessage extends StatelessWidget {
  const _TripScopedMessage({
    required this.destination,
    required this.icon,
    required this.message,
  });

  final HamweDestination destination;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _TripScopedScaffold(
      destination: destination,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppColors.muted),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

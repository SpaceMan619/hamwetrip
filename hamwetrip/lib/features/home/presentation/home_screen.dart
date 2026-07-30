import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_routes.dart';
import '../../../core/state/view_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/util/date_format.dart';
import '../../../core/widgets/hamwe_bottom_navigation.dart';
import '../../../data/models/trip_summary.dart';
import '../../rajveer/presentation/rajveer_screens.dart';
import '../home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    final profileState = ref.watch(currentUserProfileProvider);
    final firstName = switch (profileState.view) {
      ViewData(:final data) when data != null && data.displayName.trim().isNotEmpty =>
        data.displayName.trim().split(RegExp(r'\s+')).first,
      _ => 'Traveller',
    };

    final tripsState = ref.watch(myTripsControllerProvider);
    final activeTrip = switch (tripsState.view) {
      ViewData(:final data) when data.isNotEmpty => data.first,
      _ => null,
    };

    final membersState = activeTrip == null
        ? null
        : ref.watch(tripMembersControllerProvider(activeTrip.id));
    final travellerCount = switch (membersState?.view) {
      ViewData(:final data) => data.length,
      _ => 0,
    };

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 108),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(
                onMenuTap: () => showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const ScreenExplorer(),
                ),
              ),
              const SizedBox(height: 14),
              Text('Hello, $firstName!', style: textTheme.headlineLarge),
              const SizedBox(height: 4),
              Text(
                'Ready for your next adventure?',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 26),
              const _SectionHeading(
                title: 'Your Active Trip',
                action: 'IN PROGRESS',
              ),
              const SizedBox(height: 12),
              if (activeTrip == null)
                const _NoActiveTripCard()
              else
                _ActiveTripCard(
                  trip: TripSummary(
                    name: activeTrip.name,
                    location: activeTrip.destination,
                    dateRange: formatDateRange(activeTrip.startDate, activeTrip.endDate),
                    travellerCount: travellerCount,
                    // The shared ledger balance is not yet computed anywhere
                    // in Phase 2 (see TripMember.balanceMinor) — 0 is a
                    // neutral placeholder, not a claim that the ledger is
                    // settled.
                    ledgerBalance: 0,
                  ),
                  onOpenItinerary: () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.dashboard, arguments: activeTrip.id),
                ),
              const SizedBox(height: 28),
              const _SectionHeading(title: 'Upcoming Trips'),
              const SizedBox(height: 12),
              const _UpcomingTripCard(),
              const SizedBox(height: 28),
              const _SectionHeading(
                title: 'Discover Rwanda',
                action: 'VIEW ALL',
              ),
              const SizedBox(height: 12),
              const _DiscoveryCard(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.createTrip),
        backgroundColor: const Color(0xFF9B4B00),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30),
      ),
      bottomNavigationBar: const HamweBottomNavigation(
        selected: HamweDestination.home,
      ),
    );
  }
}

class _NoActiveTripCard extends StatelessWidget {
  const _NoActiveTripCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.explore_outlined, color: AppColors.forest),
          const SizedBox(height: 10),
          Text('No trip yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            "Tap the + button to plan your group's first trip.",
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onMenuTap});

  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    Widget roundButton(IconData icon) => Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.forest, size: 22),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onMenuTap,
          child: roundButton(Icons.menu_rounded),
        ),
        roundButton(Icons.notifications_none_rounded),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.action});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: action == 'IN PROGRESS'
                  ? AppColors.paleSunset
                  : AppColors.sand,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              action!,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
      ],
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  const _ActiveTripCard({required this.trip, required this.onOpenItinerary});

  final TripSummary trip;
  final VoidCallback onOpenItinerary;

  @override
  Widget build(BuildContext context) {
    final money =
        'RWF ${trip.ledgerBalance.toString().replaceAllMapped(RegExp(r'(?=(\\d{3})+(?!\\d))'), (match) => ',')}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 212,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            alignment: Alignment.bottomLeft,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE5BC6C),
                  Color(0xFF7E804C),
                  Color(0xFF183F1B),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.terrain_rounded,
                  color: Colors.white70,
                  size: 30,
                ),
                const SizedBox(height: 6),
                Text(
                  trip.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${trip.dateRange} - ${trip.travellerCount} Travelers',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _StatusRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'SHARED LEDGER',
                  value: money,
                  color: AppColors.paleSunset,
                ),
                const SizedBox(height: 10),
                const _StatusRow(
                  icon: Icons.sync_rounded,
                  label: 'SYNC STATUS',
                  value: 'All changes saved',
                  color: AppColors.paleMint,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onOpenItinerary,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Open Itinerary'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warmSand,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.forest),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingTripCard extends StatelessWidget {
  const _UpcomingTripCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 262,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.landscape_outlined, color: Color(0xFF685E3E)),
              Spacer(),
              Text('In 14 Days', style: TextStyle(fontSize: 11)),
            ],
          ),
          SizedBox(height: 22),
          Text(
            'Lake Kivu Retreat',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 3),
          Text('Rubavu, Rwanda', style: TextStyle(color: AppColors.muted)),
          SizedBox(height: 18),
          Text('4 travelers', style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DiscoveryCard extends StatelessWidget {
  const _DiscoveryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 245,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      alignment: Alignment.bottomLeft,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF628067), Color(0xFF1B3F28)],
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ADVENTURE AWAITS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Nyungwe National Park',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Explore Rwanda's ancient rainforest from above.",
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

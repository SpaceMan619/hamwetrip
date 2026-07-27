import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/trip_summary.dart';
import '../../rajveer/presentation/rajveer_screens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.trip = TripSummary.demo});

  final TripSummary trip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
              Text('Hello, Malik!', style: textTheme.headlineLarge),
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
              _ActiveTripCard(
                trip: trip,
                onOpenItinerary: () =>
                    Navigator.of(context).pushNamed(AppRoutes.dashboard),
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
        onPressed: () {},
        backgroundColor: const Color(0xFF9B4B00),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30),
      ),
      bottomNavigationBar: _MainNavigation(
        onTripsTap: () => Navigator.of(context).pushNamed(AppRoutes.dashboard),
        onProfileTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
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

class _MainNavigation extends StatelessWidget {
  const _MainNavigation({required this.onTripsTap, required this.onProfileTap});

  final VoidCallback onTripsTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Home', true),
      (Icons.explore_outlined, 'Trips', false),
      (Icons.account_balance_wallet_outlined, 'Ledger', false),
      (Icons.lock_outline_rounded, 'Vault', false),
      (Icons.person_outline_rounded, 'Profile', false),
    ];
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final item in items)
              _NavItem(
                icon: item.$1,
                label: item.$2,
                selected: item.$3,
                onTap: item.$2 == 'Trips'
                    ? onTripsTap
                    : item.$2 == 'Profile'
                    ? onProfileTap
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.forest : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Icon(
          icon,
          size: 22,
          color: selected ? Colors.white : AppColors.ink,
        ),
      ),
    );
  }
}

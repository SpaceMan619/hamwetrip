import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../theme/app_colors.dart';

enum HamweDestination { home, trips, ledger, vault, profile }

class HamweBottomNavigation extends StatelessWidget {
  const HamweBottomNavigation({super.key, required this.selected});

  final HamweDestination selected;

  static const _items = [
    (HamweDestination.home, Icons.home_rounded, 'Home'),
    (HamweDestination.trips, Icons.explore_outlined, 'Trips'),
    (HamweDestination.ledger, Icons.account_balance_wallet_outlined, 'Ledger'),
    (HamweDestination.vault, Icons.lock_outline_rounded, 'Vault'),
    (HamweDestination.profile, Icons.person_outline_rounded, 'Profile'),
  ];

  void _open(BuildContext context, HamweDestination destination) {
    if (destination == selected) return;

    final route = switch (destination) {
      HamweDestination.home => AppRoutes.home,
      HamweDestination.trips => AppRoutes.dashboard,
      HamweDestination.profile => AppRoutes.profile,
      HamweDestination.ledger || HamweDestination.vault => null,
    };

    if (route == null) {
      final name = destination == HamweDestination.ledger ? 'Ledger' : 'Vault';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '$name will connect when Shakira\'s screens are merged.',
            ),
          ),
        );
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.line.withValues(alpha: .45)),
          borderRadius: BorderRadius.circular(36),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F2D5A27),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final item in _items)
              _NavigationItem(
                icon: item.$2,
                label: item.$3,
                selected: selected == item.$1,
                onTap: () => _open(context, item.$1),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 13 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.forestLight : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 21,
                color: selected ? AppColors.mint : AppColors.ink,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.ink,
                  fontSize: 9,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    // map the selected pill item to its feature route.
    if (destination == selected) return;

    // ✅ UPDATED: Now maps Ledger and Vault to the real Shakira screens
    final route = switch (destination) {
      HamweDestination.home => AppRoutes.home,
      HamweDestination.trips => AppRoutes.dashboard,
      HamweDestination.ledger => AppRoutes.expenseSplitting,
      HamweDestination.vault => AppRoutes.documentVault,
      HamweDestination.profile => AppRoutes.profile,
    };

    Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    // keep the floating pill safe above the phone home indicator.
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        height: 64,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xB8FFFFFF), Color(0x30FFFFFF), Color(0x80FFFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E222F30),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
            BoxShadow(
              color: Color(0x18222F30),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: const Color(0xDDF7F7F5),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: .62)),
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
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.charcoal.withValues(alpha: .09)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 21,
                color: selected ? AppColors.accent : AppColors.charcoal,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: SizedBox(
                  width: selected ? 48 : 0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: const TextStyle(
                        color: AppColors.charcoal,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

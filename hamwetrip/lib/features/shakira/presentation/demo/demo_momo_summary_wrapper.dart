import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/repository_providers.dart';
import '../momo_summary_screen.dart';
import 'controllers/demo_momo_controller.dart';
import '../../../../core/widgets/hamwe_bottom_navigation.dart';
import '../../../../core/widgets/trip_scoped.dart';

/// Wires up MoMo data from Firestore to the pure UI screen.
class DemoMomoSummaryWrapper extends StatelessWidget {
  const DemoMomoSummaryWrapper({super.key});

  @override
  Widget build(BuildContext context) => TripScoped(
    destination: HamweDestination.ledger,
    builder: (tripId) =>
        _MomoSummaryView(key: ValueKey(tripId), tripId: tripId),
  );
}

class _MomoSummaryView extends ConsumerStatefulWidget {
  const _MomoSummaryView({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<_MomoSummaryView> createState() =>
      _DemoMomoSummaryWrapperState();
}

class _DemoMomoSummaryWrapperState extends ConsumerState<_MomoSummaryView> {
  late final DemoMomoController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DemoMomoController(
      repository: ref.read(momoRepositoryProvider),
      tripId: widget.tripId,
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_controller.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.warmSand,
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: const HamweBottomNavigation(
          selected: HamweDestination.ledger,
        ),
      );
    }

    // Error state
    if (_controller.hasError) {
      return Scaffold(
        backgroundColor: AppColors.warmSand,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _controller.error?.message ?? 'Something went wrong',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _controller.retry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const HamweBottomNavigation(
          selected: HamweDestination.ledger,
        ),
      );
    }

    return MomoSummaryScreen(
      toSend: _controller.toSend,
      toReceive: _controller.toReceive,
      totalSendAmount: _controller.totalSendAmount,
      totalReceiveAmount: _controller.totalReceiveAmount,
      bottomNavigation: const HamweBottomNavigation(
        selected: HamweDestination.ledger,
      ),
      onPayNow: (tx) async {
        await _controller.payNow(tx.id);
        if (!context.mounted) return;
        if (_controller.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _controller.error?.message ?? 'Failed to send payment',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sent ${tx.amount.toStringAsFixed(0)} RWF to ${tx.name} via MoMo!',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.forest,
            ),
          );
        }
      },
      onRequest: (tx) async {
        await _controller.requestPayment(tx.id);
        if (!context.mounted) return;
        if (_controller.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _controller.error?.message ?? 'Failed to request payment',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'MoMo request sent to ${tx.name} for ${tx.amount.toStringAsFixed(0)} RWF!',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.forest,
            ),
          );
        }
      },
      fabLabel: 'Send Request',
      onFabTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Send new request form coming soon'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}

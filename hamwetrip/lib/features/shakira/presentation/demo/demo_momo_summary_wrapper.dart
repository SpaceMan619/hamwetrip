import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../momo_summary_screen.dart';
import 'controllers/demo_momo_controller.dart';
import '../../../../../core/widgets/hamwe_bottom_navigation.dart';

/// Wires up mock MoMo data to your pure UI screen.
class DemoMomoSummaryWrapper extends StatefulWidget {
  const DemoMomoSummaryWrapper({super.key});

  @override
  State<DemoMomoSummaryWrapper> createState() => _DemoMomoSummaryWrapperState();
}

class _DemoMomoSummaryWrapperState extends State<DemoMomoSummaryWrapper> {
  late final DemoMomoController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DemoMomoController();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // connect local payment state to the summary screen.
    return MomoSummaryScreen(
      toSend: _controller.toSend,
      toReceive: _controller.toReceive,
      totalSendAmount: _controller.totalSendAmount,
      totalReceiveAmount: _controller.totalReceiveAmount,
      bottomNavigation: const HamweBottomNavigation(
        selected: HamweDestination.ledger,
      ),

      // Fixes "Empty Handler" - Pay Now button in "To Send" tab
      onPayNow: (tx) {
        _controller.payNow(tx.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sent ${tx.amount.toStringAsFixed(0)} RWF to ${tx.name} via MoMo! (Demo)',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.forest,
          ),
        );
      },

      // Fixes "Empty Handler" - Request button in "To Receive" tab
      onRequest: (tx) {
        _controller.requestPayment(tx.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'MoMo request sent to ${tx.name} for ${tx.amount.toStringAsFixed(0)} RWF! (Demo)',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.forest,
          ),
        );
      },

      // Fixes "Empty Handler" - FAB
      fabLabel: 'Send Request',
      onFabTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Send new request form will be available after backend integration',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}

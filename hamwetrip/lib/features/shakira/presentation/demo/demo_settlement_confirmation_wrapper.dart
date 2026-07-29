import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/expense.dart';
import '../../../../../data/models/settlement_args.dart';
import '../settlement_confirmation_screen.dart';

/// Wires up mock processing state to your pure UI screen.
class DemoSettlementConfirmationWrapper extends StatefulWidget {
  const DemoSettlementConfirmationWrapper({super.key});

  @override
  State<DemoSettlementConfirmationWrapper> createState() =>
      _DemoSettlementConfirmationWrapperState();
}

class _DemoSettlementConfirmationWrapperState
    extends State<DemoSettlementConfirmationWrapper> {
  bool _isProcessing = true;
  late SettlementArgs _args;

  @override
  void initState() {
    super.initState();

    // 1. Grab arguments passed from the Expense screen
    final args = ModalRoute.of(context)?.settings.arguments as SettlementArgs?;

    if (args != null) {
      _args = args;
    } else {
      // Fallback dummy data if opened directly from Screen Explorer
      _args = const SettlementArgs(
        balance: Balance(
          fromInitials: 'SK',
          fromName: 'Shakira',
          toInitials: 'RM',
          toName: 'Rajveer Malik',
          amount: 20000,
        ),
        maskedPhone: '*** *** 456',
        referenceId: 'MTN-DEMO-001',
      );
    }

    // 2. Simulate the 2-second MoMo processing time
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SettlementConfirmationScreen(
      args: _args,
      isProcessing: _isProcessing,

      // Fixes "Empty Handler" - Close / Back to ledger
      onDone: () {
        Navigator.of(context).pop(); // Go back to expenses
      },

      // Fixes "Empty Handler" - Share receipt
      onShareReceipt: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('MoMo receipt copied to clipboard! (Simulated)'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.forest,
          ),
        );
      },
    );
  }
}

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
  bool _didReadArguments = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArguments) return;
    _didReadArguments = true;

    _args =
        ModalRoute.of(context)?.settings.arguments as SettlementArgs? ??
        const SettlementArgs(
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

  @override
  Widget build(BuildContext context) {
    return SettlementConfirmationScreen(
      args: _args,
      isProcessing: _isProcessing,

      onDone: () {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        }
      },

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

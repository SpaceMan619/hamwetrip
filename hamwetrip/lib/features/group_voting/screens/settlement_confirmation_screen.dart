import 'dart:async';
import 'package:flutter/material.dart';
import '../models/settlement_args.dart';

class SettlementConfirmationScreen extends StatefulWidget {
  final SettlementArgs args;

  const SettlementConfirmationScreen({super.key, required this.args});

  @override
  State<SettlementConfirmationScreen> createState() =>
      _SettlementConfirmationScreenState();
}

class _SettlementConfirmationScreenState
    extends State<SettlementConfirmationScreen> {
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    // Simulate a 2-second MoMo processing delay
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
  }

  void _handleShareReceipt() {
    debugPrint('Share receipt tapped for Ref: ${widget.args.referenceId}');
  }

  void _handleDone() {
    // Pops back to the previous screen (MoMo or Expenses)
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = MediaQuery.of(context).size.width > 600;
    final horizontalPadding = isTablet ? 48.0 : 24.0;
    final maxWidth = isTablet ? 500.0 : double.infinity;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Hide back button during success
        actions: [
          if (!_isProcessing)
            IconButton(
              onPressed: _handleDone,
              icon: const Icon(Icons.close),
              tooltip: 'Close',
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 40,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- Status Icon & Text ---
                _StatusHeader(
                  isProcessing: _isProcessing,
                  colorScheme: colorScheme,
                  theme: theme,
                ),

                const SizedBox(height: 40),

                // --- Amount Display ---
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: _isProcessing ? 0.5 : value,
                      child: Transform.scale(
                        scale: _isProcessing ? 0.8 : value,
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    '\$${widget.args.balance.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _isProcessing ? 'Processing...' : 'Transfer Successful',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _isProcessing
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 40),

                // --- Transaction Details Card ---
                TweenAnimationBuilder<Offset>(
                  tween: Tween(begin: const Offset(0, 20), end: Offset.zero),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  builder: (context, offset, child) {
                    return Transform.translate(
                      offset: _isProcessing ? const Offset(0, 20) : offset,
                      child: Opacity(
                        opacity: _isProcessing ? 0.0 : 1.0,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        _DetailRow(
                          label: 'Sent to',
                          value: widget.args.balance.toName,
                          theme: theme,
                          colorScheme: colorScheme,
                        ),
                        const Divider(height: 32),
                        _DetailRow(
                          label: 'Phone Number',
                          value: widget.args.maskedPhone,
                          theme: theme,
                          colorScheme: colorScheme,
                          isMono: true,
                        ),
                        const Divider(height: 32),
                        _DetailRow(
                          label: 'For Trip',
                          value: 'Kigali City Tour',
                          theme: theme,
                          colorScheme: colorScheme,
                        ),
                        const Divider(height: 32),
                        _DetailRow(
                          label: 'Reference ID',
                          value: widget.args.referenceId,
                          theme: theme,
                          colorScheme: colorScheme,
                          isMono: true,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // --- Action Buttons ---
                if (!_isProcessing) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _handleDone,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Back to Expenses'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _handleShareReceipt,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Share Receipt'),
                    ),
                  ),
                ] else
                  const SizedBox(
                    height: 100,
                  ), // Preserve layout height during loading
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Helper Widgets ---

class _StatusHeader extends StatelessWidget {
  final bool isProcessing;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _StatusHeader({
    required this.isProcessing,
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: isProcessing
                ? colorScheme.surfaceContainerHighest
                : colorScheme.primaryContainer,
            shape: BoxShape.circle,
            boxShadow: isProcessing
                ? []
                : [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Center(
            child: isProcessing
                ? SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                : Icon(
                    Icons.check_rounded,
                    size: 50,
                    color: colorScheme.primary,
                  ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Settlement Confirmed',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isProcessing
              ? 'Please wait while we process your payment...'
              : 'The balance has been updated successfully.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final bool isMono;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.theme,
    required this.colorScheme,
    this.isMono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              fontFamily: isMono ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamwetrip/app/app_routes.dart';
import 'package:hamwetrip/core/widgets/shakira_widgets/poll_option_tile.dart';
import 'package:hamwetrip/data/models/expense.dart';
import 'package:hamwetrip/data/models/settlement_args.dart';
import 'package:hamwetrip/features/shakira/presentation/demo/demo_group_voting_wrapper.dart';
import 'package:hamwetrip/features/shakira/presentation/demo/demo_poll_results_wrapper.dart';
import 'package:hamwetrip/features/shakira/presentation/demo/demo_settlement_confirmation_wrapper.dart';

void main() {
  testWidgets('an option can be selected and submitted as a vote', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: DemoGroupVotingWrapper()));

    await tester.tap(find.text('Friday afternoon').first);
    await tester.pump();
    expect(find.widgetWithText(FilledButton, 'Vote'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Vote'));
    await tester.pump();
    expect(find.text('Voted'), findsOneWidget);
    expect(find.textContaining('Vote recorded successfully'), findsOneWidget);
  });

  testWidgets('multiple options remain selected before submitting', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: DemoGroupVotingWrapper()));

    await tester.tap(find.text('Visit Kimironko Market').first);
    await tester.pump();
    await tester.tap(find.text('Gorilla trekking').first);
    await tester.pump();

    final selectedOptions = tester
        .widgetList<PollOptionTile>(find.byType(PollOptionTile))
        .where((option) => option.isSelected);
    expect(selectedOptions, hasLength(2));
    expect(find.widgetWithText(FilledButton, 'Vote'), findsOneWidget);
  });

  testWidgets('settlement arguments are read safely from the route', (
    tester,
  ) async {
    const args = SettlementArgs(
      balance: Balance(
        fromInitials: 'RM',
        fromName: 'Rajveer Malik',
        toInitials: 'SK',
        toName: 'Shakira',
        amount: 25000,
      ),
      maskedPhone: '*** *** 123',
      referenceId: 'MTN-TEST-001',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(AppRoutes.settlementConfirmation, arguments: args),
            child: const Text('Open settlement'),
          ),
        ),
        routes: {
          AppRoutes.settlementConfirmation: (_) =>
              const DemoSettlementConfirmationWrapper(),
        },
      ),
    );

    await tester.tap(find.text('Open settlement'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('RWF 25000'), findsOneWidget);
    expect(find.text('TRANSACTION SETTLED'), findsOneWidget);
  });

  testWidgets('poll results has useful demo data when opened directly', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DemoPollResultsWrapper()));

    expect(find.text('Poll Results'), findsOneWidget);
    expect(find.text('Private van or public transport?'), findsOneWidget);
  });
}

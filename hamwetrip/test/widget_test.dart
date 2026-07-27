import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamwetrip/app/hamwe_trip_app.dart';
import 'package:hamwetrip/features/rajveer/presentation/rajveer_screens.dart';

void main() {
  testWidgets('shows the HamweTrip home screen', (tester) async {
    await tester.pumpWidget(const HamweTripApp());

    expect(find.text('Hello, Malik!'), findsOneWidget);
  });

  testWidgets('shows the Rajveer screen explorer', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ScreenExplorer())),
    );

    expect(find.text('Onboarding'), findsOneWidget);
    expect(find.text('Rajveer - screen explorer'), findsOneWidget);
  });
}

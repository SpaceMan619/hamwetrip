import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamwetrip/app/hamwe_trip_app.dart';
import 'package:hamwetrip/core/providers/repository_providers.dart';
import 'package:hamwetrip/core/widgets/hamwe_bottom_navigation.dart';
import 'package:hamwetrip/data/mock/mock_backend.dart';
import 'package:hamwetrip/features/rajveer/presentation/rajveer_screens.dart';

/// Wraps [child] in a ProviderScope backed by the seeded in-memory mocks.
///
/// Latency is zeroed so a widget test does not have to pump through the
/// artificial delay the mocks use to make loading states visible during
/// manual development.
Widget wrapped(Widget child) {
  return ProviderScope(
    overrides: [
      useMockRepositoriesProvider.overrideWithValue(true),
      mockBackendProvider.overrideWith((ref) {
        final backend = MockBackend.seeded(latency: Duration.zero);
        ref.onDispose(backend.dispose);
        return backend;
      }),
    ],
    child: child,
  );
}

void main() {
  testWidgets('shows the HamweTrip home screen', (tester) async {
    await tester.pumpWidget(wrapped(const HamweTripApp()));
    // Settle rather than a single pump: the greeting starts at its
    // 'Traveller' fallback and only becomes the real name once the profile
    // stream emits, which is a frame later even at zero latency.
    await tester.pumpAndSettle();

    // The seeded backend signs in as Aline Uwase, so the greeting is now
    // driven by real profile data rather than a hardcoded name.
    expect(find.text('Hello, Aline!'), findsOneWidget);
    expect(find.byType(HamweBottomNavigation), findsOneWidget);
  });

  testWidgets('shows the Rajveer screen explorer', (tester) async {
    await tester.pumpWidget(
      wrapped(const MaterialApp(home: Scaffold(body: ScreenExplorer()))),
    );
    await tester.pump();

    expect(find.text('Onboarding'), findsOneWidget);
    expect(find.text('Rajveer - screen explorer'), findsOneWidget);
  });

  testWidgets('uses pill navigation only where the design requires it', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapped(const MaterialApp(home: TripDashboardScreen())),
    );
    await tester.pump();
    expect(find.byType(HamweBottomNavigation), findsOneWidget);

    await tester.pumpWidget(
      wrapped(const MaterialApp(home: CreateTripScreen())),
    );
    await tester.pump();
    expect(find.byType(HamweBottomNavigation), findsOneWidget);

    await tester.pumpWidget(
      wrapped(const MaterialApp(home: InviteMembersScreen())),
    );
    await tester.pump();
    expect(find.byType(HamweBottomNavigation), findsNothing);
  });
}

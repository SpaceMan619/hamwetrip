import 'package:flutter_test/flutter_test.dart';
import 'package:hamwetrip/main.dart';

void main() {
  testWidgets('shows the HamweTrip app shell', (tester) async {
    await tester.pumpWidget(const HamweTripApp());

    expect(find.text('HamweTrip'), findsOneWidget);
  });
}

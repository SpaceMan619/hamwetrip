import 'package:flutter_test/flutter_test.dart';
import 'package:hamwetrip/app/hamwe_trip_app.dart';

void main() {
  testWidgets('shows the HamweTrip home screen', (tester) async {
    await tester.pumpWidget(const HamweTripApp());

    expect(find.text('Hello, Malik!'), findsOneWidget);
  });
}

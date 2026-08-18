import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/features/activity/view/passenger_rating_page.dart';

void main() {
  testWidgets('rating page remains usable and identifies the driver', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PassengerRatingPage(
          driverId: 'driver-1',
          driverName: 'Demo Driver',
          rideId: 'ride-1',
        ),
      ),
    );

    expect(find.text('Demo Driver'), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsNWidgets(5));

    await tester.tap(find.byIcon(Icons.star_border).first);
    await tester.pump();

    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsNWidgets(4));
  });
}

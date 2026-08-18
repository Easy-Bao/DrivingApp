import 'package:driver_app/src/features/trip/view/ride_alert_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('accepts numeric session ids from the server response', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RideAlertPage(
          rideData: {
            'id': 101,
            'pickup_name': 'Pickup',
            'dropoff_name': 'Dropoff',
            'distance': 1.5,
            'fare': 31.59,
            'duration': '5 min',
          },
        ),
      ),
    );

    expect(find.text('New Ride Request'), findsOneWidget);
    expect(find.text('Accept Ride'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('keeps malformed ride data inside a safe fallback state', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RideAlertPage()));

    expect(find.text('New Ride Request'), findsOneWidget);
    expect(find.text('Pickup location unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

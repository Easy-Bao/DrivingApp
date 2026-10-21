import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_no_driver_panel.dart';

void main() {
  const destination = Place(
    id: 'destination-1',
    name: 'Destination',
    fullAddress: 'Destination address',
    latitude: 7.83,
    longitude: 123.44,
  );

  testWidgets('offers a real ride request after empty discovery', (
    tester,
  ) async {
    var retryCount = 0;
    var requestCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FindingDriverNoDriverPanel(
            fare: 100,
            destination: destination,
            pickupAddress: 'Pickup address',
            rideType: 'Solo Ride',
            onRequestRidePressed: () => requestCount++,
            onRetryPressed: () => retryCount++,
            onCancelPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('No nearby drivers yet'), findsOneWidget);
    expect(
      find.textContaining('You can request a ride anyway'),
      findsOneWidget,
    );
    expect(find.textContaining('Solo Ride'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    await tester.tap(find.text('Request a ride'));
    await tester.pump();
    expect(requestCount, 1);

    await tester.tap(find.text('Check again'));
    await tester.pump();

    expect(retryCount, 1);
  });
}

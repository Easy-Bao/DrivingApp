import 'package:flutter/material.dart';
import 'package:maps/maps.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_no_driver_panel_widget.dart';

void main() {
  const destination = Place(
    id: 'destination-1',
    name: 'Destination',
    fullAddress: 'Destination address',
    latitude: 7.83,
    longitude: 123.44,
  );

  testWidgets('allows the passenger to retry finding a driver', (tester) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FindingDriverNoDriverPanelWidget(
            rideType: 'Solo Ride',
            fare: 100,
            destination: destination,
            onRetryPressed: () => retryCount++,
            onCancelPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('No driver found'), findsOneWidget);
    await tester.tap(find.text('Try again'));

    expect(retryCount, 1);
  });
}

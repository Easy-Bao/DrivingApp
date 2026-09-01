import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_availability_error_panel_widget.dart';

void main() {
  const destination = Place(
    id: 'destination-1',
    name: 'Destination',
    fullAddress: 'Destination address',
    latitude: 7.83,
    longitude: 123.44,
  );

  testWidgets('keeps the passenger on the search flow with retry', (
    tester,
  ) async {
    var retryCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FindingDriverAvailabilityErrorPanelWidget(
            message: 'We could not check driver availability right now.',
            fare: 100,
            destination: destination,
            onRetryPressed: () => retryCount++,
            onCancelPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Driver search unavailable'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retryCount, 1);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_searching_panel.dart';

void main() {
  const destination = Place(
    id: 'destination-1',
    name: 'Destination',
    fullAddress: 'Destination address',
    latitude: 7.83,
    longitude: 123.44,
  );

  testWidgets('keeps searching copy independent of ride type', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FindingDriverSearchingPanel(
            message: 'Finding a driver',
            fare: 100,
            destination: destination,
            dotAnimation: const AlwaysStoppedAnimation<double>(0),
            onCancelPressed: () {},
          ),
        ),
      ),
    );

    expect(
      find.text('We’re checking which drivers are currently nearby.'),
      findsOneWidget,
    );
    expect(find.textContaining('Solo'), findsNothing);
  });

  testWidgets(
    'shows route, request reference, ride type, and cash for an open request',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FindingDriverSearchingPanel(
              message: 'Finding your driver.',
              fare: 100,
              destination: destination,
              pickupAddress: 'Pickup address',
              rideType: 'Solo Ride',
              requestId: '31',
              requestCreated: true,
              dotAnimation: const AlwaysStoppedAnimation<double>(0),
              onCancelPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Request ID 31'), findsOneWidget);
      expect(find.text('Pickup address'), findsOneWidget);
      expect(find.text('Destination'), findsOneWidget);
      expect(find.text('Solo Ride'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(
        find.text(
          'Your request is open. We’ll update this screen when a driver responds.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel request'), findsOneWidget);
    },
  );
}

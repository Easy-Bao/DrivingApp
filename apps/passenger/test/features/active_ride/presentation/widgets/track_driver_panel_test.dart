import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/active_ride/domain/entities/ride_snapshot.dart';
import 'package:passenger/src/features/active_ride/presentation/widgets/track_driver_panel.dart';

void main() {
  testWidgets('exposes an accessible emergency action for active rides', (
    tester,
  ) async {
    var emergencyPressed = false;
    var reportPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: Scaffold(
          body: TrackDriverPanel(
            ride: const RideSnapshot(
              id: 'ride-1',
              pickupName: 'Pickup',
              dropoffName: 'Destination',
              pickupLatitude: 14.6,
              pickupLongitude: 120.98,
              dropoffLatitude: 14.61,
              dropoffLongitude: 120.99,
              status: 'accepted',
              driverId: 'driver-1',
              driverName: 'Alex',
              plateNumber: 'ABC 123',
              vehicleType: 'Sedan',
            ),
            statusTitle: 'Driver assigned',
            statusSubtitle: 'Driver is heading to pickup',
            etaText: '5 min',
            unreadChatMessagesCount: 0,
            onCallDriverPressed: () {},
            onChatDriverPressed: () {},
            onEmergencyPressed: () => emergencyPressed = true,
            onReportDriverPressed: () => reportPressed = true,
            onCancelTripPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Emergency SOS'), findsOneWidget);
    expect(
      tester
          .getSize(find.widgetWithText(OutlinedButton, 'Emergency SOS'))
          .height,
      48,
    );

    await tester.tap(find.text('Emergency SOS'));

    expect(emergencyPressed, isTrue);
    await tester.tap(find.text('Report Issue'));

    expect(reportPressed, isTrue);
  });

  testWidgets('keeps emergency access during an in-progress trip', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: Scaffold(
          body: TrackDriverPanel(
            ride: const RideSnapshot(
              id: 'ride-1',
              pickupName: 'Pickup',
              dropoffName: 'Destination',
              pickupLatitude: 14.6,
              pickupLongitude: 120.98,
              dropoffLatitude: 14.61,
              dropoffLongitude: 120.99,
              status: 'in_transit',
              driverId: 'driver-1',
              driverName: 'Alex',
              plateNumber: 'ABC 123',
              vehicleType: 'Sedan',
            ),
            statusTitle: 'Heading to destination',
            statusSubtitle: 'Trip in progress',
            etaText: '8 min',
            unreadChatMessagesCount: 0,
            showContactActions: false,
            onCallDriverPressed: () {},
            onChatDriverPressed: () {},
            onEmergencyPressed: () {},
            onReportDriverPressed: () {},
            onCancelTripPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Emergency SOS'), findsOneWidget);
    expect(find.text('Cancel ride'), findsNothing);
  });
}

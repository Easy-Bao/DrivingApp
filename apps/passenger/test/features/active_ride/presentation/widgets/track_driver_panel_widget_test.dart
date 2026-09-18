import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/active_ride/presentation/widgets/track_driver_panel_widget.dart';
import 'package:passenger/src/features/ride_history/domain/entities/ride_history.dart';

void main() {
  testWidgets('exposes an accessible emergency action for active rides', (
    tester,
  ) async {
    var emergencyPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.main,
        home: Scaffold(
          body: TrackDriverPanelWidget(
            ride: const RideHistory(
              id: 'ride-1',
              pickup: 'Pickup',
              destination: 'Destination',
              pickupLat: 14.6,
              pickupLng: 120.98,
              destLat: 14.61,
              destLng: 120.99,
              date: '2026-09-18',
              price: '₱100',
              status: 'accepted',
              driverId: 'driver-1',
              driverName: 'Alex',
              vehiclePlate: 'ABC 123',
              vehicleType: 'Sedan',
            ),
            statusTitle: 'Driver assigned',
            statusSubtitle: 'Driver is heading to pickup',
            etaText: '5 min',
            unreadChatMessagesCount: 0,
            onCallDriverPressed: () {},
            onChatDriverPressed: () {},
            onEmergencyPressed: () => emergencyPressed = true,
            onCancelTripPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Emergency SOS'), findsOneWidget);
    expect(tester.getSize(find.byType(OutlinedButton)).height, 48);

    await tester.tap(find.text('Emergency SOS'));

    expect(emergencyPressed, isTrue);
  });
}

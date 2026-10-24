import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/active_ride/domain/entities/ride_snapshot.dart';
import 'package:passenger/src/features/active_ride/presentation/widgets/track_driver_panel.dart';

void main() {
  testWidgets(
    'shows live ETA and defers details on a compact large-text screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: TrackDriverPanel(
                  ride: const RideSnapshot(
                    id: 'ride-compact',
                    bookingReference: 'reference-compact',
                    pickupName: 'Mountain View',
                    dropoffName: 'Charleston Park',
                    status: 'accepted',
                    fareAmount: 2788,
                  ),
                  statusTitle: 'Driver is on the way',
                  statusSubtitle: 'Mountain View',
                  etaText: '6 min',
                  driverName: 'A driver with a long full name',
                  vehicleSummary: 'Tricycle · ABC 1234',
                  unreadChatMessagesCount: 2,
                  onChatDriverPressed: () {},

                  onReportDriverPressed: () {},
                  onCancelTripPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('6 min'), findsOneWidget);
      expect(find.textContaining('Booking ID'), findsNothing);
      expect(tester.takeException(), isNull);
      expect(find.text('Trip details'), findsNothing);
      expect(find.textContaining('Booking ID'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keeps reporting accessible without duplicate trip details', (
    tester,
  ) async {
    var reportPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
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
            onChatDriverPressed: () {},

            onReportDriverPressed: () => reportPressed = true,
            onCancelTripPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Emergency SOS'), findsNothing);
    expect(find.text('Trip details'), findsNothing);
    await tester.tap(find.text('Report issue'));

    expect(reportPressed, isTrue);
  });

  testWidgets('keeps reporting accessible during an in-progress trip', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
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
            onChatDriverPressed: () {},

            onReportDriverPressed: () {},
            onCancelTripPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Emergency SOS'), findsNothing);
    expect(find.text('Report issue'), findsOneWidget);
    expect(find.text('Cancel ride'), findsNothing);
  });

  testWidgets('hides rating pill when no driver rating is available', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: TrackDriverPanel(
            ride: const RideSnapshot(
              id: 'ride-1',
              pickupName: 'Pickup',
              dropoffName: 'Destination',
              status: 'accepted',
              driverName: 'Driver Name',
            ),
            statusTitle: 'Heading to destination',
            statusSubtitle: 'Trip in progress',
            etaText: '8 min',
            unreadChatMessagesCount: 0,
            onChatDriverPressed: () {},

            onReportDriverPressed: () {},
            onCancelTripPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('4.9 (240+)'), findsNothing);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });

  testWidgets('displays driver rating badge when provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.main,
        home: Scaffold(
          body: TrackDriverPanel(
            ride: const RideSnapshot(
              id: 'ride-1',
              pickupName: 'Pickup',
              dropoffName: 'Destination',
              status: 'accepted',
              driverName: 'Driver Name',
              driverRating: 4.8,
            ),
            statusTitle: 'Heading to destination',
            statusSubtitle: 'Trip in progress',
            etaText: '8 min',
            unreadChatMessagesCount: 0,
            onChatDriverPressed: () {},

            onReportDriverPressed: () {},
            onCancelTripPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('4.9 (240+)'), findsNothing);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });

  testWidgets(
    'hides cancel action when isInTransit is true even if ride snapshot status is accepted',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.main,
          home: Scaffold(
            body: TrackDriverPanel(
              ride: const RideSnapshot(
                id: 'ride-1',
                pickupName: 'Pickup',
                dropoffName: 'Destination',
                status: 'accepted',
                driverName: 'Driver Name',
              ),
              statusTitle: 'Heading to destination',
              statusSubtitle: 'Trip in progress',
              etaText: '8 min',
              unreadChatMessagesCount: 0,
              isInTransit: true,
              onChatDriverPressed: () {},

              onReportDriverPressed: () {},
              onCancelTripPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Cancel ride'), findsNothing);
    },
  );
}

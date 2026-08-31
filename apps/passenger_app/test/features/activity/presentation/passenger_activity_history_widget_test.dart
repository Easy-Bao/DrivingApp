import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/features/activity/presentation/widgets/passenger_activity_history_widget.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  final referenceTime = DateTime(2026, 8, 22, 18);

  final rides = [
    _ride(
      id: 'completed-today',
      destination: 'Aikido of Mountain View',
      date: 'Aug 22, 2:57 PM',
      price: '₱79.72',
      status: 'completed',
    ),
    _ride(
      id: 'completed-yesterday',
      destination: 'Vista Slope',
      date: 'Aug 21, 5:02 PM',
      price: '₱27.64',
      status: 'completed',
    ),
    _ride(
      id: 'cancelled-yesterday',
      destination: 'Grand Terrace Homes',
      date: 'Aug 21, 6:40 PM',
      price: '₱25.00',
      status: 'canceled',
    ),
    _ride(
      id: 'completed-prior-week',
      destination: 'Shoreline Park',
      date: '2026-08-14T15:44:00',
      price: '₱10.00',
      status: 'completed',
    ),
  ];

  testWidgets(
    'summarizes this week and groups dates without repeated driver labels',
    (tester) async {
      await _pumpHistory(tester, rides: rides, referenceTime: referenceTime);

      expect(find.text('₱107'), findsOneWidget);
      final rideCount = tester.widget<Text>(
        find.byKey(const ValueKey<String>('activity-weekly-ride-count')),
      );
      expect(rideCount.data, '2');
      expect(find.text('Today · Aug 22'), findsOneWidget);
      expect(find.text('Yesterday · Aug 21'), findsOneWidget);
      expect(find.text('2:57 PM · Solo ride'), findsOneWidget);
      expect(find.text('Driver'), findsNothing);
      expect(find.text('Cash'), findsNothing);
    },
  );

  testWidgets(
    'filters history inline while keeping the weekly summary stable',
    (tester) async {
      await _pumpHistory(tester, rides: rides, referenceTime: referenceTime);

      await tester.tap(
        find.byKey(const ValueKey<String>('activity-filter-cancelled')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Grand Terrace Homes'), findsOneWidget);
      expect(find.text('Aikido of Mountain View'), findsNothing);
      expect(find.text('Vista Slope'), findsNothing);
      expect(find.text('₱107'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('activity-filter-completed')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Grand Terrace Homes'), findsNothing);
      expect(find.text('Aikido of Mountain View'), findsOneWidget);
    },
  );

  testWidgets('compact card remains tappable without overflowing at 320px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? selectedRideId;
    final narrowRide = _ride(
      id: 'narrow-ride',
      destination:
          'A very long destination that must remain inside the compact card',
      date: 'Aug 22, 2:57 PM',
      price: '₱123456789.00',
      status: 'completed',
    );

    await _pumpHistory(
      tester,
      rides: [narrowRide],
      referenceTime: referenceTime,
      onRideTap: (ride) => selectedRideId = ride.id,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('past-ride-narrow-ride')),
    );
    await tester.pump();

    expect(selectedRideId, 'narrow-ride');
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps an active ride prominent and actionable', (tester) async {
    String? selectedRideId;
    final activeRide = _ride(
      id: 'active-ride',
      destination: 'Vista Slope',
      date: 'Aug 22, 5:15 PM',
      price: '₱27.64',
      status: 'accepted',
    );

    await _pumpHistory(
      tester,
      rides: const [],
      activeRides: [activeRide],
      referenceTime: referenceTime,
      onRideTap: (ride) => selectedRideId = ride.id,
    );

    expect(find.text('Active ride'), findsOneWidget);
    expect(find.text('Driver confirmed'), findsOneWidget);
    expect(find.text('Vista Slope'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('active-ride-active-ride')),
    );
    await tester.pump();

    expect(selectedRideId, 'active-ride');
  });
}

Future<void> _pumpHistory(
  WidgetTester tester, {
  required List<RideHistoryModel> rides,
  required DateTime referenceTime,
  List<RideHistoryModel> activeRides = const [],
  ValueChanged<RideHistoryModel>? onRideTap,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: EasyRideTheme.light,
      home: Scaffold(
        body: PassengerActivityHistoryWidget(
          activeRides: activeRides,
          pastRides: rides,
          referenceTime: referenceTime,
          onRideTap: onRideTap ?? (_) {},
        ),
      ),
    ),
  );
}

RideHistoryModel _ride({
  required String id,
  required String destination,
  required String date,
  required String price,
  required String status,
}) {
  return RideHistoryModel(
    id: id,
    pickup: 'Mountain View',
    destination: destination,
    pickupLat: 0,
    pickupLng: 0,
    destLat: 0,
    destLng: 0,
    date: date,
    price: price,
    status: status,
    driverId: 'driver-1',
    driverName: 'Driver',
    vehiclePlate: 'ABC-123',
    vehicleType: 'Solo',
  );
}

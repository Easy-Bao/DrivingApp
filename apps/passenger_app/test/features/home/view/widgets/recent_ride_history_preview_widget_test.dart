import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/features/home/view/widgets/recent_ride_history_preview_widget.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  const rides = [
    RideHistoryModel(
      id: 'ride-1',
      pickup: 'Mountain View',
      destination: '2025 Garcia Avenue',
      pickupLat: 0,
      pickupLng: 0,
      destLat: 0,
      destLng: 0,
      date: '2026-08-18',
      price: '₱28.17',
      status: 'completed',
      driverId: 'driver-1',
      driverName: 'Driver One',
      vehiclePlate: '',
      vehicleType: '',
    ),
    RideHistoryModel(
      id: 'ride-2',
      pickup: 'Mountain View',
      destination: 'Aikido of Mountain View',
      pickupLat: 0,
      pickupLng: 0,
      destLat: 0,
      destLng: 0,
      date: '2026-08-17',
      price: '₱29.72',
      status: 'completed',
      driverId: 'driver-2',
      driverName: 'Driver Two',
      vehiclePlate: '',
      vehicleType: '',
    ),
    RideHistoryModel(
      id: 'ride-3',
      pickup: 'Mountain View',
      destination: 'Shoreline Park',
      pickupLat: 0,
      pickupLng: 0,
      destLat: 0,
      destLng: 0,
      date: '2026-08-16',
      price: '₱31.00',
      status: 'completed',
      driverId: 'driver-3',
      driverName: 'Driver Three',
      vehiclePlate: '',
      vehicleType: '',
    ),
  ];

  testWidgets('renders all rides supplied by the activity history preview', (
    tester,
  ) async {
    String? selectedRideId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 500,
            child: RecentRideHistoryPreviewWidget(
              rides: rides,
              onRideTap: (ride) => selectedRideId = ride.id,
            ),
          ),
        ),
      ),
    );

    expect(find.text('2025 Garcia Avenue'), findsOneWidget);
    expect(find.text('Aikido of Mountain View'), findsOneWidget);
    expect(find.text('Shoreline Park'), findsOneWidget);

    await tester.tap(find.text('Aikido of Mountain View'));
    expect(selectedRideId, 'ride-2');
  });
}

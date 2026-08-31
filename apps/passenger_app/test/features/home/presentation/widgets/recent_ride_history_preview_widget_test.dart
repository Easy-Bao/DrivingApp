import 'package:ride/ride.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/features/home/presentation/widgets/recent_ride_history_preview_widget.dart';

void main() {
  const rides = [
    RideHistory(
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
    RideHistory(
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
    RideHistory(
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
    RideHistory(
      id: 'ride-4',
      pickup: 'Mountain View',
      destination: 'Googleplex',
      pickupLat: 0,
      pickupLng: 0,
      destLat: 0,
      destLng: 0,
      date: '2026-08-15',
      price: '₱32.00',
      status: 'completed',
      driverId: 'driver-4',
      driverName: 'Driver Four',
      vehiclePlate: '',
      vehicleType: '',
    ),
    RideHistory(
      id: 'ride-5',
      pickup: 'Mountain View',
      destination: 'Charleston Road',
      pickupLat: 0,
      pickupLng: 0,
      destLat: 0,
      destLng: 0,
      date: '2026-08-14',
      price: '₱33.00',
      status: 'completed',
      driverId: 'driver-5',
      driverName: 'Driver Five',
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
            height: 180,
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

    await tester.tap(find.text('Aikido of Mountain View'));
    expect(selectedRideId, 'ride-2');

    await tester.scrollUntilVisible(
      find.text('Charleston Road'),
      120,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
    expect(find.text('Charleston Road'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/active_ride/domain/entities/ride_snapshot.dart';

void main() {
  test('destructures canonical and legacy snapshot fields', () {
    final snapshot = RideSnapshot.fromJson(const {
      'id': 303,
      'status': ' Accepted ',
      'pickup': 'Terminal A',
      'destination': 'Terminal B',
      'passengerId': 7,
      'passengerName': 'Passenger',
      'driverId': 42,
      'driverName': 'Nearby Driver',
      'vehicleType': 'Bao Bao',
      'plateNumber': 'ABC 1234',
      'pickupLat': '7.828',
      'pickupLng': 123.434,
      'dropoffLatitude': 7.9,
      'dropoffLongitude': '123.5',
      'distance': '4.5',
      'durationMinutes': 12,
      'fare': '125.50',
    });

    expect(snapshot.id, '303');
    expect(snapshot.status, 'accepted');
    expect(snapshot.pickupName, 'Terminal A');
    expect(snapshot.dropoffName, 'Terminal B');
    expect(snapshot.passengerId, '7');
    expect(snapshot.passengerName, 'Passenger');
    expect(snapshot.driverId, '42');
    expect(snapshot.driverName, 'Nearby Driver');
    expect(snapshot.vehicleType, 'Bao Bao');
    expect(snapshot.plateNumber, 'ABC 1234');
    expect(snapshot.pickupLatitude, 7.828);
    expect(snapshot.pickupLongitude, 123.434);
    expect(snapshot.dropoffLatitude, 7.9);
    expect(snapshot.dropoffLongitude, 123.5);
    expect(snapshot.distanceKm, 4.5);
    expect(snapshot.durationMinutes, 12);
    expect(snapshot.fareCentavos, 12550);
    expect(snapshot.farePesos, 125.5);
  });

  test('keeps fallback identifiers and defaults for sparse snapshots', () {
    final snapshot = RideSnapshot.fromJson(const {
      'status': 'requested',
    }, fallbackId: 'session-303');

    expect(snapshot.id, 'session-303');
    expect(snapshot.status, 'requested');
    expect(snapshot.pickupName, 'Pickup');
    expect(snapshot.dropoffName, 'Dropoff');
    expect(snapshot.fareCentavos, isNull);
    expect(snapshot.isTerminal, isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/active_ride/domain/entities/ride_status.dart';
import 'package:passenger/src/features/active_ride/domain/entities/ride_update.dart';

void main() {
  test('destructures canonical and legacy payload fields into one update', () {
    final update = RideUpdate.fromJson(const {
      'status': 'accepted',
      'driverId': 42,
      'driverName': 'Nearby Driver',
      'vehiclePlate': 'ABC 1234',
      'vehicleType': 'Bao Bao',
      'pickup_latitude': '7.828',
      'pickup_longitude': 123.434,
      'dropoff_latitude': 7.9,
      'dropoff_longitude': '123.5',
    });

    expect(update.status, RideStatus.accepted);
    expect(update.driverId, '42');
    expect(update.driverName, 'Nearby Driver');
    expect(update.vehiclePlate, 'ABC 1234');
    expect(update.vehicleType, 'Bao Bao');
    expect(update.pickupLat, 7.828);
    expect(update.pickupLng, 123.434);
    expect(update.destinationLat, 7.9);
    expect(update.destinationLng, 123.5);
  });

  test('retains defaults when optional payload fields are absent', () {
    final update = RideUpdate.fromJson(const {'status': 'requested'});

    expect(update.status, RideStatus.requested);
    expect(update.driverId, isNull);
    expect(update.driverName, 'Driver');
    expect(update.vehiclePlate, '—');
    expect(update.vehicleType, 'Bao Bao');
    expect(update.pickupLat, isNull);
    expect(update.destinationLng, isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/ride_history/domain/entities/ride_history.dart';

void main() {
  test('destructures legacy ride-history aliases with safe coercion', () {
    final ride = RideHistory.fromJson(const {
      'id': 11,
      'pickup_name': 'Makati',
      'dropoff_name': 'BGC',
      'pickup_latitude': '14.5547',
      'pickup_longitude': 121.0244,
      'dropoff_latitude': 14.5491,
      'dropoff_longitude': '121.0500',
      'completed_at': '2026-09-04T08:00:00Z',
      'fare': 215.5,
      'status': 'completed',
      'driver_id': 7,
      'driver_name': 'Alex',
      'plate_number': 'ABC 123',
      'vehicle_type': 'Bao Premium',
      'driverRating': '4.75',
    });

    expect(ride.id, '11');
    expect(ride.pickup, 'Makati');
    expect(ride.destination, 'BGC');
    expect(ride.pickupLat, 14.5547);
    expect(ride.pickupLng, 121.0244);
    expect(ride.destLat, 14.5491);
    expect(ride.destLng, 121.05);
    expect(ride.date, '2026-09-04T08:00:00Z');
    expect(ride.price, '215.5');
    expect(ride.driverId, '7');
    expect(ride.driverRating, 4.75);
    expect(ride.displayVehicleSummary, 'Bao Premium • ABC 123');
  });
}

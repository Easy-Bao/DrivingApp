import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/booking/domain/entities/driver_model.dart';

void main() {
  test('destructures matching payload aliases into a driver model', () {
    final driver = DriverModel.fromJson(const {
      'user_id': 42,
      'driverName': 'Nearby Driver',
      'vehicle_type': 'Bao Bao',
      'plateNumber': 'ABC 1234',
      'rating': '4.9',
      'lat': 7.828,
      'lng': '123.434',
      'distance_km': 1.25,
      'etaMinutes': '3.5',
      'score': 0.98,
      'onboard_passenger_count': '1',
      'avatar_url': 'https://example.test/avatar.png',
      'recent_feedback': 'Smooth pickup',
    });

    expect(driver.id, '42');
    expect(driver.name, 'Nearby Driver');
    expect(driver.vehicleType, 'Bao Bao');
    expect(driver.plateNumber, 'ABC 1234');
    expect(driver.rating, 4.9);
    expect(driver.lat, 7.828);
    expect(driver.lng, 123.434);
    expect(driver.distanceKm, 1.25);
    expect(driver.etaMinutes, 3.5);
    expect(driver.score, 0.98);
    expect(driver.onboardPassengerCount, 1);
    expect(driver.avatarUrl, 'https://example.test/avatar.png');
    expect(driver.recentFeedback, 'Smooth pickup');
    expect(driver.hasPassengerOnboard, isTrue);
  });

  test('keeps safe numeric defaults for sparse discovery payloads', () {
    final driver = DriverModel.fromJson(const {});

    expect(driver.id, isEmpty);
    expect(driver.rating, 0);
    expect(driver.lat, 0);
    expect(driver.lng, 0);
    expect(driver.distanceKm, 0);
    expect(driver.etaMinutes, 0);
    expect(driver.score, 0);
    expect(driver.onboardPassengerCount, isNull);
    expect(driver.vehicleSummary, 'Vehicle details unavailable');
  });
}

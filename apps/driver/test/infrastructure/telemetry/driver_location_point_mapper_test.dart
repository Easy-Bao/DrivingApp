import 'package:driver/src/infrastructure/telemetry/driver_location_point_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  test('preserves the sensor timestamp and clamps motion values', () {
    final timestamp = DateTime(
      2026,
      10,
      8,
      12,
      30,
    ).add(const Duration(microseconds: 4321));
    final point = driverLocationPointFromPosition(
      _position(timestamp: timestamp, heading: 361, speed: 250),
    );

    expect(point.latitude, 6.9271);
    expect(point.longitude, 79.8612);
    expect(point.observedAt, timestamp.toUtc());
    expect(point.heading, 360);
    expect(point.speed, 200);
  });

  test('replaces invalid motion values with zero', () {
    final point = driverLocationPointFromPosition(
      _position(heading: -1, speed: double.nan),
    );

    expect(point.heading, 0);
    expect(point.speed, 0);
  });
}

Position _position({
  DateTime? timestamp,
  required double heading,
  required double speed,
}) {
  return Position(
    longitude: 79.8612,
    latitude: 6.9271,
    timestamp: timestamp ?? DateTime.utc(2026, 10, 8),
    accuracy: 4,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: heading,
    headingAccuracy: 0,
    speed: speed,
    speedAccuracy: 0,
  );
}

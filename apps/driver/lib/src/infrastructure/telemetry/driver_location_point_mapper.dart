import 'package:driver/src/infrastructure/telemetry/driver_location_spool.dart';
import 'package:geolocator/geolocator.dart';

DriverLocationPoint driverLocationPointFromPosition(Position position) {
  return DriverLocationPoint(
    latitude: position.latitude,
    longitude: position.longitude,
    observedAt: position.timestamp.toUtc(),
    heading: position.heading.isFinite && position.heading >= 0
        ? position.heading.clamp(0, 360).toDouble()
        : 0,
    speed: position.speed.isFinite && position.speed >= 0
        ? position.speed.clamp(0, 200).toDouble()
        : 0,
  );
}

import 'package:driver_app/src/rust/api/map_api.dart' as rust_api;
import 'package:geolocator/geolocator.dart';

/// Device location service using geolocator.
/// Provider-agnostic — works regardless of map provider.
class LocationService {
  LocationService._();

  static Position? _lastPosition;

  /// Returns the last known position (cached).
  static Position? get lastPosition => _lastPosition;

  /// Check and request location permissions.
  /// Returns true if permission is granted.
  static Future<bool> checkAndRequestPermission() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Get the current device position.
  /// Caches result for quick re-access.
  static Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) return null;

    try {
      _lastPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
      return _lastPosition;
    } catch (e) {
      return null;
    }
  }

  /// Calculate distance between two coordinates in kilometers using Rust.
  static Future<double> distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    return await rust_api.haversineDistance(
      lat1: startLat,
      lng1: startLng,
      lat2: endLat,
      lng2: endLng,
    );
  }
}

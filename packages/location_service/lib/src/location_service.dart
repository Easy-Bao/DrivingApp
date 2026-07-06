/// Location Service: handles coordinates tracking, distance calculations, and hardware access checks.
library;

import 'package:geolocator/geolocator.dart';
import 'map_native_service.dart';

class LocationService {
  LocationService._();

  static Position? _lastPosition;
  static MapNativeService? _nativeService;

  static void initialize(MapNativeService nativeService) {
    _nativeService = nativeService;
  }

  static Position? get lastPosition => _lastPosition;

  static Future<bool> isServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

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
    } catch (_) {
      return null;
    }
  }

  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).map((pos) {
      _lastPosition = pos;
      return pos;
    });
  }

  static Future<double> distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    final nativeService = _nativeService;
    if (nativeService == null) {
      throw StateError(
        'LocationService not initialized. Call initialize() first.',
      );
    }
    return await nativeService.haversineDistance(
      lat1: startLat,
      lng1: startLng,
      lat2: endLat,
      lng2: endLng,
    );
  }
}

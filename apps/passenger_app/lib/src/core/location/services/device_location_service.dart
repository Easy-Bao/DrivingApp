import 'package:geolocator/geolocator.dart';
import 'package:passenger_app/src/core/location/repositories/map_native_service.dart';

enum LocationAccessState { ready, serviceDisabled, denied, deniedForever }

class LocationService {
  LocationService._();

  static Position? _lastPosition;
  static MapNativeService? _nativeService;

  static set nativeService(MapNativeService nativeService) {
    _nativeService = nativeService;
  }

  static Position? get lastPosition => _lastPosition;

  static Future<bool> isServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  static Future<LocationAccessState> getAccessState() async {
    if (!await isServiceEnabled()) {
      return LocationAccessState.serviceDisabled;
    }

    return _stateForPermission(await Geolocator.checkPermission());
  }

  static Future<LocationAccessState> refresh() => getAccessState();

  static Future<bool> requestPermission() async {
    if (!await isServiceEnabled()) return false;
    final state = _stateForPermission(await Geolocator.requestPermission());
    return state == LocationAccessState.ready;
  }

  static Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  static Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  static Future<Position?> getCurrentPosition() async {
    if (await getAccessState() != LocationAccessState.ready) return null;

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

  static LocationAccessState _stateForPermission(
    LocationPermission permission,
  ) {
    return switch (permission) {
      LocationPermission.deniedForever => LocationAccessState.deniedForever,
      LocationPermission.denied => LocationAccessState.denied,
      LocationPermission.unableToDetermine => LocationAccessState.denied,
      LocationPermission.whileInUse ||
      LocationPermission.always => LocationAccessState.ready,
    };
  }

  static Future<double> distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    final nativeService = _nativeService;
    if (nativeService == null) {
      throw StateError('LocationService not initialized.');
    }
    return await nativeService.haversineDistance(
      lat1: startLat,
      lng1: startLng,
      lat2: endLat,
      lng2: endLng,
    );
  }
}

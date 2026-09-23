import 'package:geolocator/geolocator.dart';

import 'package:maps/src/map/map_native_service.dart';

enum LocationAccessState { ready, serviceDisabled, denied, deniedForever }

class LocationService._() {
  static Position? _lastPosition;
  static MapNativeService? _nativeService;

  static set nativeService(MapNativeService nativeService) {
    _nativeService = nativeService;
  }

  static Position? get lastPosition => _lastPosition;

  static Future<bool> isServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  static Future<LocationAccessState> getAccessState() async {
    try {
      if (!await isServiceEnabled()) {
        return LocationAccessState.serviceDisabled;
      }

      return _stateForPermission(await Geolocator.checkPermission());
    } catch (_) {
      return LocationAccessState.denied;
    }
  }

  static Future<LocationAccessState> refresh() => getAccessState();

  static Stream<LocationAccessState> get accessStateChanges =>
      Geolocator.getServiceStatusStream()
          .asyncMap((_) => getAccessState())
          .distinct();

  static Future<bool> requestPermission() async {
    try {
      if (!await isServiceEnabled()) return false;
      final state = _stateForPermission(await Geolocator.requestPermission());
      return state == LocationAccessState.ready;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  static Future<Position?> getCurrentPosition() async {
    try {
      if (await getAccessState() != LocationAccessState.ready) return null;

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
    try {
      return Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          )
          .map((pos) {
            _lastPosition = pos;
            return pos;
          })
          .handleError((Object _) {});
    } catch (_) {
      return const Stream<Position>.empty();
    }
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

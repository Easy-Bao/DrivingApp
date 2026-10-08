import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:foundation/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'package:maps/src/map/map_native_service.dart';

enum LocationAccessState { ready, serviceDisabled, denied, deniedForever }

class LocationService._() {
  static Position? _lastPosition;
  static Position? _lastStreamPosition;
  static DateTime? _lastStreamReceivedAt;
  static int _streamSampleCount = 0;
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

      final position = await traceTimelineStage(
        'maps.location.current_position',
        () => Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
            timeLimit: Duration(seconds: 5),
          ),
        ),
      );
      _lastPosition = position;
      if (!kReleaseMode) {
        developer.Timeline.instantSync(
          'maps.location.current_fix',
          arguments: {
            'sample_age_ms': DateTime.now()
                .toUtc()
                .difference(position.timestamp)
                .inMilliseconds,
            'accuracy_m': position.accuracy,
          },
        );
      }
      return position;
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
            _recordStreamSample(pos);
            return pos;
          })
          .handleError((Object _) {});
    } catch (_) {
      return const Stream<Position>.empty();
    }
  }

  static void _recordStreamSample(Position position) {
    if (kReleaseMode) return;

    final receivedAt = DateTime.now().toUtc();
    final previousPosition = _lastStreamPosition;
    final previousReceivedAt = _lastStreamReceivedAt;
    _lastStreamPosition = position;
    _lastStreamReceivedAt = receivedAt;
    _streamSampleCount++;
    if (_streamSampleCount % 10 != 0) return;

    developer.Timeline.instantSync(
      'maps.location.stream_sample',
      arguments: {
        'sample_count': _streamSampleCount,
        'sample_age_ms': receivedAt
            .difference(position.timestamp)
            .inMilliseconds,
        'accuracy_m': position.accuracy,
        if (previousPosition != null)
          'observed_interval_ms': position.timestamp
              .difference(previousPosition.timestamp)
              .inMilliseconds,
        if (previousReceivedAt != null)
          'received_interval_ms': receivedAt
              .difference(previousReceivedAt)
              .inMilliseconds,
      },
    );
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

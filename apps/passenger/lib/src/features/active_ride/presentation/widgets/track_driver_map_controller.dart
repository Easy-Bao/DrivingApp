import 'dart:async';
import 'dart:typed_data';

import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';

class TrackDriverMapUpdate {
  const TrackDriverMapUpdate({
    required this.driverLatitude,
    required this.driverLongitude,
    required this.routePoints,
    required this.status,
  });

  final double driverLatitude;
  final double driverLongitude;
  final List<List<double>>? routePoints;
  final RideStatus status;
}

class TrackDriverMapController {
  TrackDriverMapController({
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.resolveRouteColor,
    required this.resolveViewportPadding,
    required this.isMounted,
  });

  static const Duration _cameraRefitCooldown = Duration(seconds: 8);

  final double pickupLatitude;
  final double pickupLongitude;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final Color Function() resolveRouteColor;
  final EdgeInsets Function() resolveViewportPadding;
  final bool Function() isMounted;

  AppMapController? _mapController;
  bool _isMapReady = false;
  bool _hasFittedInitialMap = false;
  bool _isUpdatingMap = false;
  TrackDriverMapUpdate? _pendingUpdate;
  DateTime? _lastCameraFitAt;

  MapPointAnnotationManager? _passengerMarkerManager;
  MapPointAnnotationManager? _driverMarkerManager;
  MapPolylineAnnotationManager? _routeLineManager;

  double? _lastDriverLat;
  double? _lastDriverLng;
  double? _lastTargetLat;
  double? _lastTargetLng;
  bool? _lastTargetIsInTransit;
  List<List<double>>? _lastRoutePoints;
  RideStatus? _lastFittedStatus;

  void onMapCreated(AppMapController controller) {
    _mapController = controller;
    _isMapReady = false;
    _hasFittedInitialMap = false;
    _lastCameraFitAt = null;
    clearAnnotations();
  }

  void onMapReady() {
    if (!isMounted() || _mapController == null) return;
    _isMapReady = true;
    _flushPendingUpdate();
  }

  void clearAnnotations() {
    for (final manager in <MapBaseAnnotationManager?>[
      _routeLineManager,
      _passengerMarkerManager,
      _driverMarkerManager,
    ]) {
      unawaited(MapProvider.clearAnnotations(manager));
    }
    _routeLineManager = null;
    _passengerMarkerManager = null;
    _driverMarkerManager = null;
    _lastDriverLat = null;
    _lastDriverLng = null;
    _lastTargetLat = null;
    _lastTargetLng = null;
    _lastTargetIsInTransit = null;
    _lastRoutePoints = null;
    _lastFittedStatus = null;
  }

  void dispose() {
    clearAnnotations();
    _mapController = null;
    _pendingUpdate = null;
  }

  Future<void> update(TrackDriverMapUpdate request) async {
    final mapController = _mapController;
    if (!isMounted() || !identical(_mapController, mapController)) return;
    if (mapController == null || !_isMapReady || _isUpdatingMap) {
      _pendingUpdate = request;
      return;
    }

    final isInTransit = request.status == RideStatus.inTransit;
    final targetLatitude = isInTransit ? dropoffLatitude : pickupLatitude;
    final targetLongitude = isInTransit ? dropoffLongitude : pickupLongitude;

    final routeChanged = !_sameRoutePoints(
      _lastRoutePoints,
      request.routePoints,
    );
    final targetChanged =
        _passengerMarkerManager == null ||
        _lastTargetLat != targetLatitude ||
        _lastTargetLng != targetLongitude ||
        _lastTargetIsInTransit != isInTransit;
    final driverMoved =
        _driverMarkerManager == null ||
        _lastDriverLat != request.driverLatitude ||
        _lastDriverLng != request.driverLongitude;
    final statusChanged = _lastFittedStatus != request.status;

    if (!routeChanged &&
        !targetChanged &&
        !driverMoved &&
        _hasFittedInitialMap) {
      return;
    }

    _isUpdatingMap = true;
    try {
      if (routeChanged) {
        final routeCoordinates = request.routePoints?.toCoordinateBuffer();
        if (routeCoordinates != null && routeCoordinates.length >= 4) {
          _routeLineManager = await _upsertRoute(
            _routeLineManager,
            mapController,
            routeCoordinates,
          );
        } else if (_routeLineManager != null) {
          await MapProvider.clearAnnotations(_routeLineManager);
          _routeLineManager = null;
        }
        if (!isMounted() || !identical(_mapController, mapController)) return;
        _lastRoutePoints = request.routePoints;
      }

      if (targetChanged) {
        _passengerMarkerManager = await _upsertMarker(
          _passengerMarkerManager,
          mapController,
          targetLatitude,
          targetLongitude,
          isOrigin: true,
          color: isInTransit
              ? TripMapMarkerStyle.tripLocation
              : TripMapMarkerStyle.ownLocation,
          animate: false,
        );
        if (!isMounted() || !identical(_mapController, mapController)) return;
        _lastTargetLat = targetLatitude;
        _lastTargetLng = targetLongitude;
        _lastTargetIsInTransit = isInTransit;
      }

      if (driverMoved) {
        _driverMarkerManager = await _upsertMarker(
          _driverMarkerManager,
          mapController,
          request.driverLatitude,
          request.driverLongitude,
          isOrigin: false,
          color: TripMapMarkerStyle.tripLocation,
          animate: _lastDriverLat != null,
        );
        if (!isMounted() || !identical(_mapController, mapController)) return;
        _lastDriverLat = request.driverLatitude;
        _lastDriverLng = request.driverLongitude;
      }

      final now = DateTime.now();
      final lastCameraFitAt = _lastCameraFitAt;
      final shouldFitCamera =
          !_hasFittedInitialMap ||
          statusChanged ||
          (driverMoved &&
              (lastCameraFitAt == null ||
                  now.difference(lastCameraFitAt) >= _cameraRefitCooldown));
      if (shouldFitCamera) {
        await MapProvider.fitBounds(
          mapController,
          [
            LatLng(targetLatitude, targetLongitude),
            LatLng(request.driverLatitude, request.driverLongitude),
          ],
          viewportPadding: resolveViewportPadding(),
          maxZoom: 15.0,
        );
        _hasFittedInitialMap = true;
        _lastCameraFitAt = now;
        _lastFittedStatus = request.status;
      }
    } catch (error) {
      debugPrint('Error updating track map: $error');
    } finally {
      _isUpdatingMap = false;
      _flushPendingUpdate();
    }
  }

  void _flushPendingUpdate() {
    if (_mapController == null || _isUpdatingMap || !isMounted()) return;
    final pending = _pendingUpdate;
    if (pending == null) return;
    _pendingUpdate = null;
    unawaited(update(pending));
  }

  Future<MapPointAnnotationManager> _upsertMarker(
    MapPointAnnotationManager? annotationManager,
    AppMapController mapController,
    double lat,
    double lng, {
    required bool isOrigin,
    required Color color,
    bool animate = false,
  }) async {
    if (annotationManager == null) {
      final manager = await MapProvider.addMarker(
        mapController,
        lat,
        lng,
        isOrigin: isOrigin,
        color: color,
      );
      if (!isMounted() || !identical(_mapController, mapController)) {
        await MapProvider.clearAnnotations(manager);
        throw StateError('Trip map was disposed during marker creation.');
      }
      return manager;
    }
    await MapProvider.replaceMarker(
      annotationManager,
      lat,
      lng,
      isOrigin: isOrigin,
      color: color,
      animate: animate,
    );
    return annotationManager;
  }

  Future<MapPolylineAnnotationManager?> _upsertRoute(
    MapPolylineAnnotationManager? annotationManager,
    AppMapController mapController,
    Float64List routeCoordinates,
  ) async {
    if (!isMounted()) return annotationManager;
    final color = resolveRouteColor();
    if (annotationManager == null) {
      final manager = await MapProvider.addPolylineBuffer(
        mapController,
        routeCoordinates,
        color: color,
        width: 4.0,
      );
      if (!isMounted() || !identical(_mapController, mapController)) {
        await MapProvider.clearAnnotations(manager);
        return null;
      }
      return manager;
    }
    await MapProvider.replacePolylineBuffer(
      annotationManager,
      routeCoordinates,
      color: color,
      width: 4.0,
    );
    return annotationManager;
  }

  static bool _sameRoutePoints(List<List<double>>? a, List<List<double>>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null || a.length != b.length) return false;
    if (a.isEmpty) return true;
    for (var i = 0; i < a.length; i++) {
      final pa = a[i];
      final pb = b[i];
      if (pa.length != pb.length) return false;
      for (var j = 0; j < pa.length; j++) {
        if (pa[j] != pb[j]) return false;
      }
    }
    return true;
  }
}

import 'package:maps/maps.dart';

import 'dart:async';
import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:rxdart/rxdart.dart';

import 'package:driver/src/features/active_ride/domain/repositories/driver_ride_repository.dart';

part 'live_map_event.dart';
part 'live_map_state.dart';

const driverRouteRefreshDeviationMeters = 50.0;

bool hasExceededRouteDeviation({
  required double originLat,
  required double originLng,
  required double currentLat,
  required double currentLng,
}) {
  final distanceKm = MapNativeService.calculateHaversine(
    originLat,
    originLng,
    currentLat,
    currentLng,
  );
  return distanceKm * 1000 > driverRouteRefreshDeviationMeters;
}

class LiveMapBloc({required this._rideRepository})
    extends Bloc<LiveMapEvent, LiveMapState> {
  final DriverRideRepository _rideRepository;

  AppMapController? _mapController;
  mapbox.PointAnnotationManager? _driverMarkerManager;
  mapbox.PointAnnotationManager? _passengerMarkerManager;
  mapbox.PointAnnotationManager? _destinationMarkerManager;
  mapbox.PolylineAnnotationManager? _routePolylineManager;
  UpdateLocationsAndDrawRouteEvent? _pendingRouteUpdate;
  String? _routeTargetKey;
  double? _routeOriginLat;
  double? _routeOriginLng;
  DateTime? _lastCameraFitAt;
  bool _hasFittedCamera = false;
  Color _routeColor = TripMapMarkerStyle.ownLocation;
  int _mapViewGeneration = 0;
  int _routeOperationGeneration = 0;

  final PublishSubject<DispatchTelemetryLocationEvent> _locationSubject =
      PublishSubject<DispatchTelemetryLocationEvent>();
  late final StreamSubscription<DispatchTelemetryLocationEvent>
  _locationSubscription;

  this : super(LiveMapInitial()) {
    on<InitializeMapEvent>(_onInitializeMap);
    on<UpdateLocationsAndDrawRouteEvent>(
      _onUpdateLocationsAndDrawRoute,
      transformer: restartable(),
    );
    on<ClearMapEvent>(_onClearMap);
    _locationSubscription = _locationSubject
        .throttleTime(const Duration(seconds: 5))
        .listen((event) => unawaited(_publishLocation(event)));
    on<DispatchTelemetryLocationEvent>((event, emit) {
      _locationSubject.add(event);
    });
  }

  Future<void> _publishLocation(DispatchTelemetryLocationEvent event) async {
    try {
      final result = await _rideRepository.publishDriverLocationResult(
        latitude: event.lat,
        longitude: event.lng,
      );
      result.fold(
        (failure) => dev.log(
          'Unable to publish driver location update: ${failure.message}',
        ),
        (_) {},
      );
    } catch (error, stackTrace) {
      dev.log(
        'Unable to publish driver location update',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _onInitializeMap(
    InitializeMapEvent event,
    Emitter<LiveMapState> emit,
  ) async {
    if (!identical(_mapController, event.controller)) {
      _invalidateMapOperations();
      final initializationGeneration = _mapViewGeneration;
      await _clearAllAnnotations();
      if (isClosed || initializationGeneration != _mapViewGeneration) {
        return;
      }
      _routeTargetKey = null;
      _routeOriginLat = null;
      _routeOriginLng = null;
      _lastCameraFitAt = null;
      _hasFittedCamera = false;
    }
    _mapController = event.controller;
    _routeColor = event.routeColor;
    emit(LiveMapReady(event.defaultLat, event.defaultLng));
    final pendingRouteUpdate = _pendingRouteUpdate;
    _pendingRouteUpdate = null;
    if (pendingRouteUpdate != null) {
      add(pendingRouteUpdate);
    }
  }

  Future<void> _onUpdateLocationsAndDrawRoute(
    UpdateLocationsAndDrawRouteEvent event,
    Emitter<LiveMapState> emit,
  ) async {
    final mapController = _mapController;
    final viewGeneration = _mapViewGeneration;
    final routeOperationGeneration = ++_routeOperationGeneration;
    if (mapController == null) {
      _pendingRouteUpdate = event;
      return;
    }

    final targetLat = event.routeTargetLat ?? event.passengerLat;
    final targetLng = event.routeTargetLng ?? event.passengerLng;
    if (targetLat == null || targetLng == null) return;

    try {
      final driverMarkerManager = await _upsertMarker(
        _driverMarkerManager,
        mapController,
        event.driverLat,
        event.driverLng,
        isOrigin: true,
        color: TripMapMarkerStyle.ownLocation,
        animate: true,
      );
      if (!_isCurrentRouteOperation(
        routeOperationGeneration,
        viewGeneration,
        mapController,
      )) {
        if (_driverMarkerManager == null) {
          await _clearAnnotations(driverMarkerManager);
        }
        return;
      }
      _driverMarkerManager = driverMarkerManager;

      if (event.routeTargetLat == null &&
          event.passengerLat != null &&
          event.passengerLng != null) {
        final passengerMarkerManager = await _upsertMarker(
          _passengerMarkerManager,
          mapController,
          event.passengerLat!,
          event.passengerLng!,
          color: TripMapMarkerStyle.tripLocation,
        );
        if (!_isCurrentRouteOperation(
          routeOperationGeneration,
          viewGeneration,
          mapController,
        )) {
          if (_passengerMarkerManager == null) {
            await _clearAnnotations(passengerMarkerManager);
          }
          return;
        }
        _passengerMarkerManager = passengerMarkerManager;
      } else {
        await _clearAnnotations(_passengerMarkerManager);
        if (!_isCurrentRouteOperation(
          routeOperationGeneration,
          viewGeneration,
          mapController,
        )) {
          return;
        }
        _passengerMarkerManager = null;
      }

      if (event.routeTargetLat != null && event.routeTargetLng != null) {
        final destinationMarkerManager = await _upsertMarker(
          _destinationMarkerManager,
          mapController,
          targetLat,
          targetLng,
          color: TripMapMarkerStyle.tripLocation,
        );
        if (!_isCurrentRouteOperation(
          routeOperationGeneration,
          viewGeneration,
          mapController,
        )) {
          if (_destinationMarkerManager == null) {
            await _clearAnnotations(destinationMarkerManager);
          }
          return;
        }
        _destinationMarkerManager = destinationMarkerManager;
      } else {
        await _clearAnnotations(_destinationMarkerManager);
        if (!_isCurrentRouteOperation(
          routeOperationGeneration,
          viewGeneration,
          mapController,
        )) {
          return;
        }
        _destinationMarkerManager = null;
      }

      final now = DateTime.now();
      if (!_hasFittedCamera ||
          _lastCameraFitAt == null ||
          now.difference(_lastCameraFitAt!) >= const Duration(seconds: 8)) {
        await MapProvider.fitBounds(
          mapController,
          [
            LatLng(event.driverLat, event.driverLng),
            LatLng(targetLat, targetLng),
          ],
          padding: 72.0,
          maxZoom: 15.0,
        );
        if (!_isCurrentRouteOperation(
          routeOperationGeneration,
          viewGeneration,
          mapController,
        )) {
          return;
        }
        _hasFittedCamera = true;
        _lastCameraFitAt = now;
      }
      if (!_isCurrentRouteOperation(
        routeOperationGeneration,
        viewGeneration,
        mapController,
      )) {
        return;
      }

      final targetKey = '$targetLat:$targetLng';
      final shouldRefreshRoute =
          _routeTargetKey != targetKey ||
          _routeOriginLat == null ||
          hasExceededRouteDeviation(
            originLat: _routeOriginLat!,
            originLng: _routeOriginLng!,
            currentLat: event.driverLat,
            currentLng: event.driverLng,
          );
      if (shouldRefreshRoute) {
        final route = await MapProvider.getRoute(
          event.driverLat,
          event.driverLng,
          targetLat,
          targetLng,
        );
        if (!_isCurrentRouteOperation(
          routeOperationGeneration,
          viewGeneration,
          mapController,
        )) {
          return;
        }
        final routeCoordinates = route?.coordinateBuffer;
        if (routeCoordinates != null && routeCoordinates.length >= 4) {
          final routePolylineManager = await _upsertRoute(
            _routePolylineManager,
            mapController,
            routeCoordinates,
          );
          if (!_isCurrentRouteOperation(
            routeOperationGeneration,
            viewGeneration,
            mapController,
          )) {
            if (_routePolylineManager == null) {
              await _clearAnnotations(routePolylineManager);
            }
            return;
          }
          _routePolylineManager = routePolylineManager;
        } else {
          await _clearAnnotations(_routePolylineManager);
          if (!_isCurrentRouteOperation(
            routeOperationGeneration,
            viewGeneration,
            mapController,
          )) {
            return;
          }
          _routePolylineManager = null;
        }
        if (!_isCurrentRouteOperation(
          routeOperationGeneration,
          viewGeneration,
          mapController,
        )) {
          return;
        }
        _routeTargetKey = targetKey;
        _routeOriginLat = event.driverLat;
        _routeOriginLng = event.driverLng;
      }

      if (_isCurrentRouteOperation(
        routeOperationGeneration,
        viewGeneration,
        mapController,
      )) {
        emit(
          LiveMapRouteUpdated(
            driverLat: event.driverLat,
            driverLng: event.driverLng,
            passengerLat: event.passengerLat,
            passengerLng: event.passengerLng,
          ),
        );
      }
    } catch (error, stackTrace) {
      dev.log(
        'Unable to update the driver route map',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _onClearMap(
    ClearMapEvent event,
    Emitter<LiveMapState> emit,
  ) async {
    _invalidateMapOperations();
    await _clearAllAnnotations();
    _routeTargetKey = null;
    _routeOriginLat = null;
    _routeOriginLng = null;
    _lastCameraFitAt = null;
    _hasFittedCamera = false;
  }

  Future<mapbox.PointAnnotationManager> _upsertMarker(
    mapbox.PointAnnotationManager? annotationManager,
    AppMapController mapController,
    double lat,
    double lng, {
    bool isOrigin = false,
    Color? color,
    String? label,
    bool animate = false,
  }) async {
    if (annotationManager == null) {
      return MapProvider.addMarker(
        mapController,
        lat,
        lng,
        isOrigin: isOrigin,
        color: color,
        label: label,
      );
    }
    await MapProvider.replaceMarker(
      annotationManager,
      lat,
      lng,
      isOrigin: isOrigin,
      color: color,
      label: label,
      animate: animate,
    );
    return annotationManager;
  }

  Future<mapbox.PolylineAnnotationManager> _upsertRoute(
    mapbox.PolylineAnnotationManager? annotationManager,
    AppMapController mapController,
    Float64List routeCoordinates,
  ) async {
    if (annotationManager == null) {
      return MapProvider.addPolylineBuffer(
        mapController,
        routeCoordinates,
        color: _routeColor,
        width: 4.0,
      );
    }
    await MapProvider.replacePolylineBuffer(
      annotationManager,
      routeCoordinates,
      color: _routeColor,
      width: 4.0,
    );
    return annotationManager;
  }

  Future<void> _clearAnnotations(
    mapbox.BaseAnnotationManager? annotationManager,
  ) async {
    if (annotationManager == null) return;
    try {
      await MapProvider.clearAnnotations(annotationManager);
    } catch (error) {
      dev.log('Error clearing driver map annotation: $error');
    }
  }

  Future<void> _clearMarkers() async {
    for (final manager in [
      _driverMarkerManager,
      _passengerMarkerManager,
      _destinationMarkerManager,
    ]) {
      try {
        await _clearAnnotations(manager);
      } catch (error) {
        dev.log('Error clearing driver map marker: $error');
      }
    }
    _driverMarkerManager = null;
    _passengerMarkerManager = null;
    _destinationMarkerManager = null;
  }

  Future<void> _clearPolylines() async {
    await _clearAnnotations(_routePolylineManager);
    _routePolylineManager = null;
  }

  Future<void> _clearAllAnnotations() async {
    await _clearMarkers();
    await _clearPolylines();
  }

  @override
  Future<void> close() async {
    _invalidateMapOperations();
    await _locationSubscription.cancel();
    await _locationSubject.close();
    await _clearAllAnnotations();
    return super.close();
  }

  void _invalidateMapOperations() {
    _mapViewGeneration++;
    _routeOperationGeneration++;
  }

  bool _isCurrentMapView(int viewGeneration, AppMapController controller) {
    return !isClosed &&
        viewGeneration == _mapViewGeneration &&
        identical(_mapController, controller);
  }

  bool _isCurrentRouteOperation(
    int routeOperationGeneration,
    int viewGeneration,
    AppMapController controller,
  ) {
    return routeOperationGeneration == _routeOperationGeneration &&
        _isCurrentMapView(viewGeneration, controller);
  }
}

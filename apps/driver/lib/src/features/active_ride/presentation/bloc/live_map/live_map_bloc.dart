import 'dart:async';
import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:driver/src/features/active_ride/domain/repositories/ride_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart' show Color, EdgeInsets;
import 'package:rxdart/rxdart.dart';

part 'live_map_event.dart';
part 'live_map_state.dart';

const driverRouteRefreshDeviationMeters = 50.0;

bool hasExceededRouteDeviation({
  required double originLatitude,
  required double originLongitude,
  required double currentLatitude,
  required double currentLongitude,
}) {
  final distanceKm = MapNativeService.calculateHaversine(
    originLatitude,
    originLongitude,
    currentLatitude,
    currentLongitude,
  );
  return distanceKm * 1000 > driverRouteRefreshDeviationMeters;
}

class LiveMapBloc({required this._rideRepository})
    extends Bloc<LiveMapEvent, LiveMapState> {
  final RideRepository _rideRepository;

  AppMapController? _mapController;
  MapPointAnnotationManager? _driverMarkerManager;
  MapPointAnnotationManager? _passengerMarkerManager;
  MapPointAnnotationManager? _destinationMarkerManager;
  MapPolylineAnnotationManager? _routePolylineManager;
  UpdateLocationsAndDrawRouteEvent? _pendingRouteUpdate;
  String? _routeTargetKey;
  double? _routeOriginLatitude;
  double? _routeOriginLongitude;
  DateTime? _lastCameraFitAt;
  bool _hasFittedCamera = false;
  (double, double)? _lastDriverPosition;
  (double, double)? _lastPassengerPosition;
  (double, double)? _lastDestinationPosition;
  Color _routeColor = TripMapMarkerStyle.ownLocation;
  int _mapViewGeneration = 0;
  int _routeOperationGeneration = 0;

  final PublishSubject<DispatchTelemetryLocationEvent> _locationSubject =
      PublishSubject<DispatchTelemetryLocationEvent>();
  late final StreamSubscription<DispatchTelemetryLocationEvent>
  _locationSubscription;

  this : super(const LiveMapInitial()) {
    on<InitializeMapEvent>(_onInitializeMap);
    on<UpdateLocationsAndDrawRouteEvent>(
      _onUpdateLocationsAndDrawRoute,
      transformer: restartable(),
    );
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
        latitude: event.latitude,
        longitude: event.longitude,
      );
      if (result case Err(:final failure)) {
        dev.log('Unable to publish driver location update: ${failure.message}');
      }
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
      _routeOriginLatitude = null;
      _routeOriginLongitude = null;
      _lastCameraFitAt = null;
      _hasFittedCamera = false;
    }
    _mapController = event.controller;
    _routeColor = event.routeColor;
    emit(LiveMapReady(event.defaultLatitude, event.defaultLongitude));
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

    final targetLatitude = event.routeTargetLatitude ?? event.passengerLatitude;
    final targetLongitude =
        event.routeTargetLongitude ?? event.passengerLongitude;
    if (targetLatitude == null || targetLongitude == null) return;

    try {
      final driverPosition = (event.driverLatitude, event.driverLongitude);
      if (_driverMarkerManager == null ||
          !_isSamePosition(_lastDriverPosition, driverPosition)) {
        final driverMarkerManager = await _upsertMarker(
          _driverMarkerManager,
          mapController,
          event.driverLatitude,
          event.driverLongitude,
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
        _lastDriverPosition = driverPosition;
      }

      final passengerLat = event.passengerLatitude;
      final passengerLng = event.passengerLongitude;
      if (event.routeTargetLatitude == null &&
          passengerLat != null &&
          passengerLng != null) {
        final passengerPosition = (passengerLat, passengerLng);
        if (_passengerMarkerManager == null ||
            !_isSamePosition(_lastPassengerPosition, passengerPosition)) {
          final passengerMarkerManager = await _upsertMarker(
            _passengerMarkerManager,
            mapController,
            passengerLat,
            passengerLng,
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
          _lastPassengerPosition = passengerPosition;
        }
      } else if (_passengerMarkerManager != null) {
        await _clearAnnotations(_passengerMarkerManager);
        if (!_isCurrentRouteOperation(
          routeOperationGeneration,
          viewGeneration,
          mapController,
        )) {
          return;
        }
        _passengerMarkerManager = null;
        _lastPassengerPosition = null;
      }

      if (event.routeTargetLatitude != null &&
          event.routeTargetLongitude != null) {
        final destinationPosition = (targetLatitude, targetLongitude);
        if (_destinationMarkerManager == null ||
            !_isSamePosition(_lastDestinationPosition, destinationPosition)) {
          final destinationMarkerManager = await _upsertMarker(
            _destinationMarkerManager,
            mapController,
            targetLatitude,
            targetLongitude,
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
          _lastDestinationPosition = destinationPosition;
        }
      } else if (_destinationMarkerManager != null) {
        await _clearAnnotations(_destinationMarkerManager);
        if (!_isCurrentRouteOperation(
          routeOperationGeneration,
          viewGeneration,
          mapController,
        )) {
          return;
        }
        _destinationMarkerManager = null;
        _lastDestinationPosition = null;
      }

      final now = DateTime.now();
      final lastCameraFitAt = _lastCameraFitAt;
      if (!_hasFittedCamera ||
          lastCameraFitAt == null ||
          now.difference(lastCameraFitAt) >= const Duration(seconds: 8)) {
        await MapProvider.fitBounds(
          mapController,
          [
            LatLng(event.driverLatitude, event.driverLongitude),
            LatLng(targetLatitude, targetLongitude),
          ],
          viewportPadding: event.viewportPadding,
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

      final targetKey = '$targetLatitude:$targetLongitude';
      final routeOriginLat = _routeOriginLatitude;
      final routeOriginLng = _routeOriginLongitude;
      final shouldRefreshRoute =
          _routeTargetKey != targetKey ||
          routeOriginLat == null ||
          routeOriginLng == null ||
          hasExceededRouteDeviation(
            originLatitude: routeOriginLat,
            originLongitude: routeOriginLng,
            currentLatitude: event.driverLatitude,
            currentLongitude: event.driverLongitude,
          );
      if (shouldRefreshRoute) {
        final route = await MapProvider.getRoute(
          event.driverLatitude,
          event.driverLongitude,
          targetLatitude,
          targetLongitude,
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
        _routeOriginLatitude = event.driverLatitude;
        _routeOriginLongitude = event.driverLongitude;
      }

      if (_isCurrentRouteOperation(
        routeOperationGeneration,
        viewGeneration,
        mapController,
      )) {
        emit(
          LiveMapRouteUpdated(
            driverLatitude: event.driverLatitude,
            driverLongitude: event.driverLongitude,
            passengerLatitude: event.passengerLatitude,
            passengerLongitude: event.passengerLongitude,
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

  Future<MapPointAnnotationManager> _upsertMarker(
    MapPointAnnotationManager? annotationManager,
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

  Future<MapPolylineAnnotationManager> _upsertRoute(
    MapPolylineAnnotationManager? annotationManager,
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
    MapBaseAnnotationManager? annotationManager,
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
    _lastDriverPosition = null;
    _lastPassengerPosition = null;
    _lastDestinationPosition = null;
  }

  static bool _isSamePosition(
    (double, double)? previous,
    (double, double) next,
  ) {
    if (previous == null) return false;
    return (previous.$1 - next.$1).abs() < 1e-6 &&
        (previous.$2 - next.$2).abs() < 1e-6;
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

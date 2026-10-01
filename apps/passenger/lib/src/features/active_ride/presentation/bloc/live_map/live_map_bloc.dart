import 'dart:async';
import 'dart:developer' as dev;
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:maps/maps.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:rxdart/rxdart.dart';

part 'live_map_event.dart';
part 'live_map_state.dart';

class LiveMapBloc({required this._trackRepository})
    extends Bloc<LiveMapEvent, LiveMapState> {
  final TrackRepository _trackRepository;

  AppMapController? _mapController;
  mapbox.PointAnnotationManager? _riderMarkerManager;
  mapbox.PointAnnotationManager? _driverMarkerManager;
  mapbox.PolylineAnnotationManager? _routePolylineManager;
  final List<mapbox.PointAnnotationManager> _markerManagers = [];
  final List<AddMapMarkerEvent> _pendingMarkers = [];
  DrawDriverToRiderRouteEvent? _pendingRoute;
  FitMapToCoordinatesEvent? _pendingCameraFit;
  Color _routeColor = TripMapMarkerStyle.ownLocation;
  int _mapViewGeneration = 0;
  int _routeOperationGeneration = 0;

  final PublishSubject<DispatchTelemetryLocationEvent> _locationSubject =
      PublishSubject<DispatchTelemetryLocationEvent>();
  late final StreamSubscription<DispatchTelemetryLocationEvent>
  _locationSubscription;

  this : super(LiveMapInitial()) {
    on<InitializeMapEvent>(_onInitializeMap);
    on<DrawDriverToRiderRouteEvent>(
      _onDrawDriverToRiderRoute,
      transformer: restartable(),
    );
    on<AddMapMarkerEvent>(_onAddMapMarker);
    on<ClearMapAnnotationsEvent>(_onClearMapAnnotations);
    on<FitMapToCoordinatesEvent>(_onFitMapToCoordinates);
    _locationSubscription = _locationSubject
        .throttleTime(const Duration(seconds: 5))
        .listen((event) => unawaited(_publishPassengerLocation(event)));
    on<DispatchTelemetryLocationEvent>((event, emit) {
      _locationSubject.add(event);
    });
  }

  Future<void> _publishPassengerLocation(
    DispatchTelemetryLocationEvent event,
  ) async {
    try {
      final result = await _trackRepository.publishPassengerLocationResult(
        rideId: event.rideId,
        latitude: event.lat,
        longitude: event.lng,
      );
      result.fold(
        (failure) =>
            dev.log('Passenger telemetry update failed: ${failure.message}'),
        (_) {},
      );
    } catch (error, stackTrace) {
      dev.log(
        'Passenger telemetry update failed',
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
      await _clearAllMarkers();
      if (isClosed || initializationGeneration != _mapViewGeneration) {
        return;
      }
    }
    _mapController = event.controller;
    _routeColor = event.routeColor;
    emit(LiveMapReady(event.defaultLat, event.defaultLng));
    final pendingMarkers = List<AddMapMarkerEvent>.from(_pendingMarkers);
    _pendingMarkers.clear();
    for (final marker in pendingMarkers) {
      add(marker);
    }
    final pendingRoute = _pendingRoute;
    _pendingRoute = null;
    if (pendingRoute != null) add(pendingRoute);
    final pendingCameraFit = _pendingCameraFit;
    _pendingCameraFit = null;
    if (pendingCameraFit != null) add(pendingCameraFit);
  }

  Future<void> _onDrawDriverToRiderRoute(
    DrawDriverToRiderRouteEvent event,
    Emitter<LiveMapState> emit,
  ) async {
    final mapController = _mapController;
    final viewGeneration = _mapViewGeneration;
    final routeOperationGeneration = ++_routeOperationGeneration;
    if (mapController == null) {
      _pendingRoute = event;
      return;
    }

    if (_riderMarkerManager == null && _markerManagers.isNotEmpty) {
      final pendingMarkerManagers = List.of(_markerManagers);
      for (final manager in pendingMarkerManagers) {
        await MapProvider.clearAnnotations(manager);
      }
      if (!_isCurrentRouteOperation(
        routeOperationGeneration,
        viewGeneration,
        mapController,
      )) {
        return;
      }
      _markerManagers.clear();
    }

    final riderMarkerManager = await _upsertMarker(
      _riderMarkerManager,
      mapController,
      event.riderLat,
      event.riderLng,
      isOrigin: true,
      color: TripMapMarkerStyle.ownLocation,
    );
    if (!_isCurrentRouteOperation(
      routeOperationGeneration,
      viewGeneration,
      mapController,
    )) {
      if (_riderMarkerManager == null) {
        await _clearAnnotations(riderMarkerManager);
      }
      return;
    }
    _riderMarkerManager = riderMarkerManager;

    final driverMarkerManager = await _upsertMarker(
      _driverMarkerManager,
      mapController,
      event.driverLat,
      event.driverLng,
      color: TripMapMarkerStyle.tripLocation,
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

    await MapProvider.fitBounds(mapController, [
      LatLng(event.riderLat, event.riderLng),
      LatLng(event.driverLat, event.driverLng),
    ]);
    if (!_isCurrentRouteOperation(
      routeOperationGeneration,
      viewGeneration,
      mapController,
    )) {
      return;
    }

    final route = await MapProvider.getRoute(
      event.driverLat,
      event.driverLng,
      event.riderLat,
      event.riderLng,
    );
    if (!_isCurrentRouteOperation(
      routeOperationGeneration,
      viewGeneration,
      mapController,
    )) {
      return;
    }
    if (route != null && route.coordinateBuffer.length >= 4) {
      final routePolylineManager = await _upsertPolyline(
        _routePolylineManager,
        mapController,
        route.coordinateBuffer,
        color: _routeColor,
        width: 5.0,
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
    }

    if (!_isCurrentRouteOperation(
      routeOperationGeneration,
      viewGeneration,
      mapController,
    )) {
      return;
    }
    emit(
      LiveMapRouteDrawn(
        riderLat: event.riderLat,
        riderLng: event.riderLng,
        driverLat: event.driverLat,
        driverLng: event.driverLng,
      ),
    );
  }

  Future<void> _onAddMapMarker(
    AddMapMarkerEvent event,
    Emitter<LiveMapState> emit,
  ) async {
    final mapController = _mapController;
    final viewGeneration = _mapViewGeneration;
    if (mapController == null) {
      _pendingMarkers.add(event);
      return;
    }

    final manager = await MapProvider.addMarker(
      mapController,
      event.lat,
      event.lng,
      isOrigin: event.isOrigin,
      label: event.label,
      color: event.isOrigin
          ? TripMapMarkerStyle.ownLocation
          : TripMapMarkerStyle.tripLocation,
      onTap: event.onTap,
    );
    if (!_isCurrentMapView(viewGeneration, mapController)) {
      await _clearAnnotations(manager);
      return;
    }
    _markerManagers.add(manager);
  }

  Future<void> _onClearMapAnnotations(
    ClearMapAnnotationsEvent event,
    Emitter<LiveMapState> emit,
  ) async {
    _invalidateMapOperations();
    _pendingMarkers.clear();
    _pendingRoute = null;
    await _clearAllMarkers();
  }

  Future<void> _clearAllMarkers() async {
    await MapProvider.clearAnnotations(_riderMarkerManager);
    await MapProvider.clearAnnotations(_driverMarkerManager);
    await MapProvider.clearAnnotations(_routePolylineManager);
    _riderMarkerManager = null;
    _driverMarkerManager = null;
    _routePolylineManager = null;
    for (final manager in _markerManagers) {
      try {
        await MapProvider.clearAnnotations(manager);
      } catch (error) {
        dev.log('Error clearing annotation marker: $error');
      }
    }
    _markerManagers.clear();
  }

  Future<mapbox.PointAnnotationManager> _upsertMarker(
    mapbox.PointAnnotationManager? manager,
    AppMapController controller,
    double lat,
    double lng, {
    String? label,
    bool isOrigin = false,
    Color? color,
    bool animate = false,
  }) async {
    if (manager == null) {
      return MapProvider.addMarker(
        controller,
        lat,
        lng,
        label: label,
        isOrigin: isOrigin,
        color: color,
      );
    }
    await MapProvider.replaceMarker(
      manager,
      lat,
      lng,
      label: label,
      isOrigin: isOrigin,
      color: color,
      animate: animate,
    );
    return manager;
  }

  Future<mapbox.PolylineAnnotationManager> _upsertPolyline(
    mapbox.PolylineAnnotationManager? manager,
    AppMapController controller,
    Float64List coordinates, {
    required Color color,
    required double width,
  }) async {
    if (manager == null) {
      return MapProvider.addPolylineBuffer(
        controller,
        coordinates,
        color: color,
        width: width,
      );
    }
    await MapProvider.replacePolylineBuffer(
      manager,
      coordinates,
      color: color,
      width: width,
    );
    return manager;
  }

  Future<void> _onFitMapToCoordinates(
    FitMapToCoordinatesEvent event,
    Emitter<LiveMapState> emit,
  ) async {
    final mapController = _mapController;
    final viewGeneration = _mapViewGeneration;
    if (mapController == null) {
      _pendingCameraFit = event;
      return;
    }
    await MapProvider.fitBounds(
      mapController,
      event.coordinates,
      maxZoom: event.maxZoom,
    );
    if (!_isCurrentMapView(viewGeneration, mapController)) return;
  }

  Future<void> _clearAnnotations(
    mapbox.BaseAnnotationManager? annotationManager,
  ) async {
    if (annotationManager == null) return;
    try {
      await MapProvider.clearAnnotations(annotationManager);
    } catch (error) {
      dev.log('Error clearing passenger map annotation: $error');
    }
  }

  @override
  Future<void> close() async {
    _invalidateMapOperations();
    await _locationSubscription.cancel();
    await _locationSubject.close();
    await _clearAllMarkers();
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

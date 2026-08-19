import 'package:driver_app/src/core/location/location.dart';
import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart' show Color;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:rxdart/rxdart.dart';

import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/trip/data/datasources/telemetry_remote_data_source.dart';
import 'package:shared_core/shared_core.dart';

part 'live_map_event.dart';
part 'live_map_state.dart';

class LiveMapBloc extends Bloc<LiveMapEvent, LiveMapState> {
  final TelemetryRemoteDataSource _telemetryDataSource;
  final SecureSessionService _sessionService;

  AppMapController? _mapController;
  mapbox.PointAnnotationManager? _driverMarkerManager;
  mapbox.PointAnnotationManager? _passengerMarkerManager;
  mapbox.PointAnnotationManager? _destinationMarkerManager;
  mapbox.PolylineAnnotationManager? _routePolylineManager;
  UpdateLocationsAndDrawRouteEvent? _pendingRouteUpdate;
  String? _routeTargetKey;
  DateTime? _lastRouteUpdateAt;
  bool _hasFittedCamera = false;

  final PublishSubject<DispatchTelemetryLocationEvent> _locationSubject =
      PublishSubject<DispatchTelemetryLocationEvent>();
  late final StreamSubscription<DispatchTelemetryLocationEvent>
  _locationSubscription;

  LiveMapBloc({
    required TelemetryRemoteDataSource telemetryDataSource,
    required SecureSessionService sessionService,
  }) : _telemetryDataSource = telemetryDataSource,
       _sessionService = sessionService,
       super(LiveMapInitial()) {
    on<InitializeMapEvent>(_onInitializeMap);
    on<UpdateLocationsAndDrawRouteEvent>(
      _onUpdateLocationsAndDrawRoute,
      transformer: (events, mapper) => events.exhaustMap(mapper),
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
      final driverId = await _sessionService.readDriverId();
      if (driverId == null || driverId.isEmpty) return;
      await _telemetryDataSource.sendLocationUpdate(
        driverId: driverId,
        lat: event.lat,
        lng: event.lng,
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
      await _clearAllAnnotations();
      _routeTargetKey = null;
      _lastRouteUpdateAt = null;
      _hasFittedCamera = false;
    }
    _mapController = event.controller;
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
    if (mapController == null) {
      _pendingRouteUpdate = event;
      return;
    }

    final targetLat = event.routeTargetLat ?? event.passengerLat;
    final targetLng = event.routeTargetLng ?? event.passengerLng;
    if (targetLat == null || targetLng == null) return;

    try {
      _driverMarkerManager = await _upsertMarker(
        _driverMarkerManager,
        mapController,
        event.driverLat,
        event.driverLng,
        isOrigin: true,
        color: AppTheme.primaryColor,
      );

      if (event.routeTargetLat == null &&
          event.passengerLat != null &&
          event.passengerLng != null) {
        _passengerMarkerManager = await _upsertMarker(
          _passengerMarkerManager,
          mapController,
          event.passengerLat!,
          event.passengerLng!,
          color: AppTheme.complete,
        );
      } else {
        await _clearAnnotations(_passengerMarkerManager);
      }

      if (event.routeTargetLat != null && event.routeTargetLng != null) {
        _destinationMarkerManager = await _upsertMarker(
          _destinationMarkerManager,
          mapController,
          targetLat,
          targetLng,
          color: AppTheme.accent,
        );
      } else {
        await _clearAnnotations(_destinationMarkerManager);
      }

      if (!_hasFittedCamera) {
        await MapProvider.fitBounds(
          mapController,
          [
            LatLng(event.driverLat, event.driverLng),
            LatLng(targetLat, targetLng),
          ],
          padding: 72.0,
          maxZoom: 15.0,
        );
        _hasFittedCamera = true;
      }

      final targetKey = '$targetLat:$targetLng';
      final lastRouteUpdateAt = _lastRouteUpdateAt;
      final shouldRefreshRoute =
          _routeTargetKey != targetKey ||
          lastRouteUpdateAt == null ||
          DateTime.now().difference(lastRouteUpdateAt) >=
              const Duration(seconds: 12);
      if (shouldRefreshRoute) {
        final route = await MapProvider.getRoute(
          event.driverLat,
          event.driverLng,
          targetLat,
          targetLng,
        );
        final routePoints = route?.validPolylinePoints;
        if (routePoints != null && routePoints.length >= 2) {
          _routePolylineManager = await _upsertRoute(
            _routePolylineManager,
            mapController,
            routePoints,
          );
        } else {
          await _clearAnnotations(_routePolylineManager);
        }
        _routeTargetKey = targetKey;
        _lastRouteUpdateAt = DateTime.now();
      }

      if (!isClosed) {
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
    await _clearAllAnnotations();
    _routeTargetKey = null;
    _lastRouteUpdateAt = null;
    _hasFittedCamera = false;
  }

  Future<mapbox.PointAnnotationManager> _upsertMarker(
    mapbox.PointAnnotationManager? annotationManager,
    AppMapController mapController,
    double lat,
    double lng, {
    bool isOrigin = false,
    Color? color,
  }) async {
    if (annotationManager == null) {
      return MapProvider.addMarker(
        mapController,
        lat,
        lng,
        isOrigin: isOrigin,
        color: color,
      );
    }
    await MapProvider.replaceMarker(
      annotationManager,
      lat,
      lng,
      isOrigin: isOrigin,
      color: color,
    );
    return annotationManager;
  }

  Future<mapbox.PolylineAnnotationManager> _upsertRoute(
    mapbox.PolylineAnnotationManager? annotationManager,
    AppMapController mapController,
    List<List<double>> routePoints,
  ) async {
    if (annotationManager == null) {
      return MapProvider.addPolyline(
        mapController,
        routePoints,
        color: AppTheme.primaryColor,
        width: 4.0,
      );
    }
    await MapProvider.replacePolyline(
      annotationManager,
      routePoints,
      color: AppTheme.primaryColor,
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
    await _locationSubscription.cancel();
    await _locationSubject.close();
    await _clearAllAnnotations();
    return super.close();
  }
}

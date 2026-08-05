import 'package:driver_app/src/core/location/location.dart';
import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/live_map/live_map_event.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/live_map/live_map_state.dart';

import 'package:rxdart/rxdart.dart';

import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/trip/data/data_sources/telemetry_remote_data_source.dart';

class LiveMapBloc extends Bloc<LiveMapEvent, LiveMapState> {
  final TelemetryRemoteDataSource _telemetryDataSource;
  final SecureSessionService _sessionService;

  AppMapController? _mapController;
  final List<dynamic> _markerManagers = [];
  final List<dynamic> _polylineManagers = [];
  UpdateLocationsAndDrawRouteEvent? _pendingRouteUpdate;

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
    on<UpdateLocationsAndDrawRouteEvent>(_onUpdateLocationsAndDrawRoute);
    on<ClearMapEvent>(_onClearMap);

    _locationSubscription = _locationSubject
        .throttleTime(const Duration(seconds: 5))
        .listen((event) async {
          final driverId = await _sessionService.readDriverId();
          if (driverId != null && driverId.isNotEmpty) {
            await _telemetryDataSource.sendLocationUpdate(
              driverId: driverId,
              lat: event.lat,
              lng: event.lng,
            );
          }
        });

    on<DispatchTelemetryLocationEvent>((event, emit) {
      _locationSubject.add(event);
    });
  }

  Future<void> _onInitializeMap(
    InitializeMapEvent event,
    Emitter<LiveMapState> emit,
  ) async {
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
    if (_mapController == null) {
      _pendingRouteUpdate = event;
      return;
    }

    await _clearAllMarkers();

    final driverManager = await MapProvider.addMarker(
      _mapController!,
      event.driverLat,
      event.driverLng,
      isOrigin: true,
      label: 'Your location\nCurrent position',
      color: AppTheme.primaryColor,
    );
    _markerManagers.add(driverManager);

    if (event.routeTargetLat == null &&
        event.passengerLat != null &&
        event.passengerLng != null) {
      final passengerManager = await MapProvider.addMarker(
        _mapController!,
        event.passengerLat!,
        event.passengerLng!,
        label: 'Passenger\nPickup location',
        color: AppTheme.complete,
      );
      _markerManagers.add(passengerManager);
    }

    final targetLat = event.routeTargetLat ?? event.passengerLat;
    final targetLng = event.routeTargetLng ?? event.passengerLng;
    if (targetLat == null || targetLng == null) return;

    if (event.routeTargetLat != null && event.routeTargetLng != null) {
      final destinationManager = await MapProvider.addMarker(
        _mapController!,
        targetLat,
        targetLng,
        label: 'Destination\nDrop-off point',
        color: AppTheme.accent,
      );
      _markerManagers.add(destinationManager);
    }

    await MapProvider.fitBounds(_mapController!, [
      LatLng(event.driverLat, event.driverLng),
      LatLng(targetLat, targetLng),
    ]);

    final route = await MapProvider.getRoute(
      event.driverLat,
      event.driverLng,
      targetLat,
      targetLng,
    );
    final routePoints = route?.polylinePoints;
    if (routePoints != null && routePoints.length >= 2) {
      final polylineManager = await MapProvider.addAnimatedPolyline(
        _mapController!,
        routePoints,
        color: AppTheme.primaryColor,
        width: 5.0,
      );
      _polylineManagers.add(polylineManager);
    }

    emit(
      LiveMapRouteUpdated(
        driverLat: event.driverLat,
        driverLng: event.driverLng,
        passengerLat: event.passengerLat,
        passengerLng: event.passengerLng,
      ),
    );
  }

  Future<void> _onClearMap(
    ClearMapEvent event,
    Emitter<LiveMapState> emit,
  ) async {
    await _clearAllMarkers();
  }

  Future<void> _clearAllMarkers() async {
    for (final manager in _markerManagers) {
      try {
        await MapProvider.clearAnnotations(manager);
      } catch (error) {
        dev.log('Error clearing driver map marker: $error');
      }
    }
    _markerManagers.clear();
    for (final manager in _polylineManagers) {
      try {
        await MapProvider.clearAnnotations(manager);
      } catch (error) {
        dev.log('Error clearing driver route: $error');
      }
    }
    _polylineManagers.clear();
  }

  @override
  Future<void> close() async {
    await _locationSubscription.cancel();
    await _locationSubject.close();
    await _clearAllMarkers();
    return super.close();
  }
}

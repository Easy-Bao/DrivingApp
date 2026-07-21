import 'dart:async';

import 'package:driver_app/src/features/trip/presentation/bloc/live_map/live_map_event.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/live_map/live_map_state.dart';
import 'package:driver_services/driver_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location_service/location_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:session_service/session_service.dart';

/// State controller managing map overlay layouts, marker assets, routing
/// sequence rendering, and real-time backend telemetry dispatching.
class LiveMapBloc extends Bloc<LiveMapEvent, LiveMapState> {
  final TelemetryRemoteDataSource _telemetryDataSource;
  final SecureSessionService _sessionService;

  AppMapController? _mapController;
  final List<dynamic> _markerManagers = [];

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
            await _telemetryDataSource.updateLocation(
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
  }

  Future<void> _onUpdateLocationsAndDrawRoute(
    UpdateLocationsAndDrawRouteEvent event,
    Emitter<LiveMapState> emit,
  ) async {
    if (_mapController == null) return;

    await _clearAllMarkers();

    final driverManager = await MapProvider.addMarker(
      _mapController!,
      event.driverLat,
      event.driverLng,
      isOrigin: true,
      label: 'Driver',
      color: const Color(0xFF222222),
    );
    if (driverManager != null) _markerManagers.add(driverManager);

    final passengerManager = await MapProvider.addMarker(
      _mapController!,
      event.passengerLat,
      event.passengerLng,
      label: 'Passenger',
      color: const Color(0xFF2E7D32),
    );
    if (passengerManager != null) _markerManagers.add(passengerManager);

    await MapProvider.fitBounds(_mapController!, [
      LatLng(event.driverLat, event.driverLng),
      LatLng(event.passengerLat, event.passengerLng),
    ]);

    final route = await MapProvider.getRoute(
      event.driverLat,
      event.driverLng,
      event.passengerLat,
      event.passengerLng,
    );
    if (route != null && route.polylinePoints.isNotEmpty) {
      await MapProvider.addPolyline(
        _mapController!,
        route.polylinePoints,
        color: const Color(0xFF222222),
        width: 5.0,
      );
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
        debugPrint('Error clearing driver map marker: $error');
      }
    }
    _markerManagers.clear();
  }

  @override
  Future<void> close() async {
    await _locationSubscription.cancel();
    await _locationSubject.close();
    await _clearAllMarkers();
    return super.close();
  }
}

import 'package:driver_app/src/core/location/location.dart';
import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui' show Color;

import 'package:flutter_bloc/flutter_bloc.dart';
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
      label: 'Current location\nYou are here',
      color: const Color(0xFF222222),
    );
    _markerManagers.add(driverManager);

    final passengerManager = await MapProvider.addMarker(
      _mapController!,
      event.passengerLat,
      event.passengerLng,
      label: 'Passenger\nPickup location',
      color: const Color(0xFF2E7D32),
    );
    _markerManagers.add(passengerManager);

    await MapProvider.fitBounds(_mapController!, [
      LatLng(event.driverLat, event.driverLng),
      LatLng(
        event.routeTargetLat ?? event.passengerLat,
        event.routeTargetLng ?? event.passengerLng,
      ),
    ]);

    final route = await MapProvider.getRoute(
      event.driverLat,
      event.driverLng,
      event.routeTargetLat ?? event.passengerLat,
      event.routeTargetLng ?? event.passengerLng,
    );
    final routePoints = route?.polylinePoints.isNotEmpty == true
        ? route!.polylinePoints
        : [
            [event.driverLng, event.driverLat],
            [
              event.routeTargetLng ?? event.passengerLng,
              event.routeTargetLat ?? event.passengerLat,
            ],
          ];
    if (routePoints.length >= 2) {
      final polylineManager = await MapProvider.addPolyline(
        _mapController!,
        routePoints,
        color: const Color(0xFF222222),
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/live_map/live_map_event.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/live_map/live_map_state.dart';
import 'package:passenger_services/passenger_services.dart';
import 'package:rxdart/rxdart.dart';

/// State controller managing map overlay layouts, marker assets, routing
/// sequence rendering, and real-time backend telemetry dispatching for passengers.
class LiveMapBloc extends Bloc<LiveMapEvent, LiveMapState> {
  final PassengerApiService _apiService;

  AppMapController? _mapController;
  final List<dynamic> _markerManagers = [];

  final PublishSubject<DispatchTelemetryLocationEvent> _locationSubject =
      PublishSubject<DispatchTelemetryLocationEvent>();
  late final StreamSubscription<DispatchTelemetryLocationEvent>
  _locationSubscription;

  LiveMapBloc({required PassengerApiService apiService})
    : _apiService = apiService,
      super(LiveMapInitial()) {
    on<InitializeMapEvent>(_onInitializeMap);
    on<DrawDriverToRiderRouteEvent>(_onDrawDriverToRiderRoute);
    on<AddMapMarkerEvent>(_onAddMapMarker);
    on<ClearMapAnnotationsEvent>(_onClearMapAnnotations);

    _locationSubscription = _locationSubject
        .throttleTime(const Duration(seconds: 5))
        .listen((event) async {
          await _apiService.updateLocation(
            rideId: event.rideId,
            lat: event.lat,
            lng: event.lng,
          );
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

  Future<void> _onDrawDriverToRiderRoute(
    DrawDriverToRiderRouteEvent event,
    Emitter<LiveMapState> emit,
  ) async {
    if (_mapController == null) return;

    await _clearAllMarkers();

    final riderManager = await MapProvider.addMarker(
      _mapController!,
      event.riderLat,
      event.riderLng,
      isOrigin: true,
      label: 'You',
    );
    if (riderManager != null) _markerManagers.add(riderManager);

    final driverManager = await MapProvider.addMarker(
      _mapController!,
      event.driverLat,
      event.driverLng,
      label: 'Driver',
      color: Colors.blue,
    );
    if (driverManager != null) _markerManagers.add(driverManager);

    await MapProvider.fitBounds(_mapController!, [
      LatLng(event.riderLat, event.riderLng),
      LatLng(event.driverLat, event.driverLng),
    ]);

    final route = await MapProvider.getRoute(
      event.driverLat,
      event.driverLng,
      event.riderLat,
      event.riderLng,
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
    if (_mapController == null) return;

    final manager = await MapProvider.addMarker(
      _mapController!,
      event.lat,
      event.lng,
      isOrigin: event.isOrigin,
      label: event.label,
      color: event.isOrigin ? null : Colors.blue,
    );
    if (manager != null) {
      _markerManagers.add(manager);
    }
  }

  Future<void> _onClearMapAnnotations(
    ClearMapAnnotationsEvent event,
    Emitter<LiveMapState> emit,
  ) async {
    await _clearAllMarkers();
  }

  Future<void> _clearAllMarkers() async {
    for (final manager in _markerManagers) {
      try {
        await MapProvider.clearAnnotations(manager);
      } catch (error) {
        debugPrint('Error clearing annotation marker: $error');
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location_service/location_service.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/live_map/live_map_event.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/live_map/live_map_state.dart';

class LiveMapBloc extends Bloc<LiveMapEvent, LiveMapState> {
  AppMapController? _mapController;
  final List<dynamic> _markerManagers = [];

  LiveMapBloc() : super(LiveMapInitial()) {
    on<InitializeMapEvent>(_onInitializeMap);
    on<UpdateLocationsAndDrawRouteEvent>(_onUpdateLocationsAndDrawRoute);
    on<ClearMapEvent>(_onClearMap);
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

    // Add Driver Marker
    final driverManager = await MapProvider.addMarker(
      _mapController!,
      event.driverLat,
      event.driverLng,
      isOrigin: true,
      label: 'Driver',
      color: const Color(0xFF222222),
    );
    if (driverManager != null) _markerManagers.add(driverManager);

    // Add Passenger Marker
    final passengerManager = await MapProvider.addMarker(
      _mapController!,
      event.passengerLat,
      event.passengerLng,
      label: 'Passenger',
      color: const Color(0xFF2E7D32),
    );
    if (passengerManager != null) _markerManagers.add(passengerManager);

    // Fit bounds to show both
    await MapProvider.fitBounds(_mapController!, [
      LatLng(event.driverLat, event.driverLng),
      LatLng(event.passengerLat, event.passengerLng),
    ]);

    // Fetch and Draw route polyline
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

    emit(LiveMapRouteUpdated(
      driverLat: event.driverLat,
      driverLng: event.driverLng,
      passengerLat: event.passengerLat,
      passengerLng: event.passengerLng,
    ));
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
      } catch (_) {}
    }
    _markerManagers.clear();
  }

  @override
  Future<void> close() async {
    await _clearAllMarkers();
    return super.close();
  }
}

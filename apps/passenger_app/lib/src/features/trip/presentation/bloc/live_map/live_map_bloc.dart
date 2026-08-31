import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui' show Color;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:maps/maps.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_track_repository.dart';
import 'package:rxdart/rxdart.dart';

part 'live_map_event.dart';
part 'live_map_state.dart';

class LiveMapBloc extends Bloc<LiveMapEvent, LiveMapState> {
  final ITrackRepository _trackRepository;

  AppMapController? _mapController;
  mapbox.PointAnnotationManager? _riderMarkerManager;
  mapbox.PointAnnotationManager? _driverMarkerManager;
  mapbox.PolylineAnnotationManager? _routePolylineManager;
  final List<mapbox.PointAnnotationManager> _markerManagers = [];
  final List<AddMapMarkerEvent> _pendingMarkers = [];
  DrawDriverToRiderRouteEvent? _pendingRoute;
  FitMapToCoordinatesEvent? _pendingCameraFit;
  Color _routeColor = TripMapMarkerStyle.ownLocation;

  final PublishSubject<DispatchTelemetryLocationEvent> _locationSubject =
      PublishSubject<DispatchTelemetryLocationEvent>();
  late final StreamSubscription<DispatchTelemetryLocationEvent>
  _locationSubscription;

  LiveMapBloc({required ITrackRepository trackRepository})
    : _trackRepository = trackRepository,
      super(LiveMapInitial()) {
    on<InitializeMapEvent>(_onInitializeMap);
    on<DrawDriverToRiderRouteEvent>(_onDrawDriverToRiderRoute);
    on<AddMapMarkerEvent>(_onAddMapMarker);
    on<ClearMapAnnotationsEvent>(_onClearMapAnnotations);
    on<FitMapToCoordinatesEvent>(_onFitMapToCoordinates);

    _locationSubscription = _locationSubject
        .throttleTime(const Duration(seconds: 5))
        .listen((event) async {
          try {
            final result = await _trackRepository.publishPassengerLocation(
              rideId: event.rideId,
              latitude: event.lat,
              longitude: event.lng,
            );
            result.fold(
              (failure) => dev.log(
                'Passenger telemetry update failed: ${failure.message}',
              ),
              (_) {},
            );
          } catch (error) {
            dev.log('Passenger telemetry update failed: $error');
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
    if (!identical(_mapController, event.controller)) {
      await _clearAllMarkers();
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
    if (_mapController == null) {
      _pendingRoute = event;
      return;
    }

    if (_riderMarkerManager == null && _markerManagers.isNotEmpty) {
      for (final manager in _markerManagers) {
        await MapProvider.clearAnnotations(manager);
      }
      _markerManagers.clear();
    }

    _riderMarkerManager = await _upsertMarker(
      _riderMarkerManager,
      _mapController!,
      event.riderLat,
      event.riderLng,
      isOrigin: true,
      color: TripMapMarkerStyle.ownLocation,
    );
    _driverMarkerManager = await _upsertMarker(
      _driverMarkerManager,
      _mapController!,
      event.driverLat,
      event.driverLng,
      color: TripMapMarkerStyle.tripLocation,
      animate: true,
    );

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
    if (route != null && route.hasGeometry) {
      _routePolylineManager = await _upsertPolyline(
        _routePolylineManager,
        _mapController!,
        route.validPolylinePoints,
        color: _routeColor,
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
    if (_mapController == null) {
      _pendingMarkers.add(event);
      return;
    }

    final manager = await MapProvider.addMarker(
      _mapController!,
      event.lat,
      event.lng,
      isOrigin: event.isOrigin,
      label: event.label,
      color: event.isOrigin
          ? TripMapMarkerStyle.ownLocation
          : TripMapMarkerStyle.tripLocation,
      onTap: event.onTap,
    );
    _markerManagers.add(manager);
  }

  Future<void> _onClearMapAnnotations(
    ClearMapAnnotationsEvent event,
    Emitter<LiveMapState> emit,
  ) async {
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
    List<List<double>> points, {
    required Color color,
    required double width,
  }) async {
    if (manager == null) {
      return MapProvider.addPolyline(
        controller,
        points,
        color: color,
        width: width,
      );
    }
    await MapProvider.replacePolyline(
      manager,
      points,
      color: color,
      width: width,
    );
    return manager;
  }

  Future<void> _onFitMapToCoordinates(
    FitMapToCoordinatesEvent event,
    Emitter<LiveMapState> emit,
  ) async {
    if (_mapController == null) {
      _pendingCameraFit = event;
      return;
    }
    await MapProvider.fitBounds(
      _mapController!,
      event.coordinates,
      maxZoom: event.maxZoom,
    );
  }

  @override
  Future<void> close() async {
    await _locationSubscription.cancel();
    await _locationSubject.close();
    await _clearAllMarkers();
    return super.close();
  }
}

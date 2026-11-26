import 'dart:developer' as dev;

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart'
    show Color, EdgeInsets, VoidCallback;

part 'live_map_event.dart';
part 'live_map_state.dart';

typedef AddMapMarkerFn = Future<MapPointAnnotationManager> Function(
  AppMapController controller,
  double lat,
  double lng, {
  String? label,
  bool isOrigin,
  Color? color,
  double? bearing,
  VoidCallback? onTap,
});

typedef FitMapBoundsFn = Future<void> Function(
  AppMapController controller,
  List<LatLng> points, {
  double padding,
  EdgeInsets? viewportPadding,
  double? maxZoom,
});

typedef ClearMapAnnotationsFn = Future<void> Function(
  MapBaseAnnotationManager? manager,
);

class LiveMapBloc extends Bloc<LiveMapEvent, LiveMapState> {
  LiveMapBloc({
    this._addMarker = MapProvider.addMarker,
    this._fitBounds = MapProvider.fitBounds,
    this._clearAnnotations = MapProvider.clearAnnotations,
  }) : super(const LiveMapInitial()) {
    on<InitializeMapEvent>(_onInitializeMap);
    on<AddMapMarkerEvent>(_onAddMapMarker);
    on<ClearMapAnnotationsEvent>(_onClearMapAnnotations);
    on<ReplaceMapMarkersEvent>(_onReplaceMapMarkers, transformer: sequential());
    on<FitMapToCoordinatesEvent>(_onFitMapToCoordinates);
  }

  final AddMapMarkerFn _addMarker;
  final FitMapBoundsFn _fitBounds;
  final ClearMapAnnotationsFn _clearAnnotations;

  AppMapController? _mapController;
  final List<MapPointAnnotationManager> _markerManagers = [];
  final List<AddMapMarkerEvent> _pendingMarkers = [];
  ReplaceMapMarkersEvent? _pendingMarkerSnapshot;
  FitMapToCoordinatesEvent? _pendingCameraFit;
  int _mapViewGeneration = 0;

  Future<void> _onInitializeMap(
    InitializeMapEvent event,
    Emitter<LiveMapState> emit,
  ) async {
    if (!identical(_mapController, event.controller)) {
      // Queue incoming marker work until the previous map is cleared.
      _mapController = null;
      _invalidateMapOperations();
      final initializationGeneration = _mapViewGeneration;
      await _clearAllMarkers();
      if (isClosed || initializationGeneration != _mapViewGeneration) {
        return;
      }
    }
    _mapController = event.controller;
    emit(LiveMapReady(event.defaultLat, event.defaultLng));
    final pendingMarkers = List<AddMapMarkerEvent>.from(_pendingMarkers);
    _pendingMarkers.clear();
    for (final marker in pendingMarkers) {
      add(marker);
    }
    final pendingSnapshot = _pendingMarkerSnapshot;
    _pendingMarkerSnapshot = null;
    if (pendingSnapshot != null) add(pendingSnapshot);
    final pendingCameraFit = _pendingCameraFit;
    _pendingCameraFit = null;
    if (pendingCameraFit != null) add(pendingCameraFit);
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

    final manager = await _addMarker(
      mapController,
      event.lat,
      event.lng,
      isOrigin: event.isOrigin,
      label: event.label,
      color:
          event.color ?? TripMapMarkerStyle.colorFor(isOrigin: event.isOrigin),
      onTap: event.onTap,
    );
    if (!_isCurrentMapView(viewGeneration, mapController)) {
      await _clearAnnotationManager(manager);
      return;
    }
    _markerManagers.add(manager);
  }

  Future<void> _onReplaceMapMarkers(
    ReplaceMapMarkersEvent event,
    Emitter<LiveMapState> emit,
  ) async {
    final controller = _mapController;
    if (controller == null) {
      _pendingMarkerSnapshot = event;
      return;
    }
    _invalidateMapOperations();
    final generation = _mapViewGeneration;
    await _clearAllMarkers();
    for (final marker in event.markers) {
      if (!_isCurrentMapView(generation, controller)) return;
      await _onAddMapMarker(marker, emit);
    }
  }

  Future<void> _onClearMapAnnotations(
    ClearMapAnnotationsEvent event,
    Emitter<LiveMapState> emit,
  ) async {
    _invalidateMapOperations();
    _pendingMarkers.clear();
    _pendingMarkerSnapshot = null;
    _pendingCameraFit = null;
    await _clearAllMarkers();
  }

  Future<void> _clearAllMarkers() async {
    final managers = List<MapPointAnnotationManager>.of(_markerManagers);
    _markerManagers.clear();
    for (final manager in managers) {
      try {
        await _clearAnnotations(manager);
      } catch (error) {
        dev.log('Error clearing annotation marker: $error');
      }
    }
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
    await _fitBounds(mapController, event.coordinates, maxZoom: event.maxZoom);
    if (!_isCurrentMapView(viewGeneration, mapController)) return;
  }

  Future<void> _clearAnnotationManager(
    MapBaseAnnotationManager? annotationManager,
  ) async {
    if (annotationManager == null) return;
    try {
      await _clearAnnotations(annotationManager);
    } catch (error) {
      dev.log('Error clearing passenger map annotation: $error');
    }
  }

  @override
  Future<void> close() async {
    _invalidateMapOperations();
    await _clearAllMarkers();
    return super.close();
  }

  void _invalidateMapOperations() {
    _mapViewGeneration++;
  }

  bool _isCurrentMapView(int viewGeneration, AppMapController controller) {
    return !isClosed &&
        viewGeneration == _mapViewGeneration &&
        identical(_mapController, controller);
  }
}

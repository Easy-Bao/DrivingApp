import 'dart:math' as math;

import 'package:equatable/equatable.dart';

typedef DemandHeatmapTileLoader<T> = Future<List<T>> Function(
  MapViewportBounds bounds,
);

class const MapViewportBounds({
  required this.minLatitude,
  required this.minLongitude,
  required this.maxLatitude,
  required this.maxLongitude,
}) {
  final double minLatitude;
  final double minLongitude;
  final double maxLatitude;
  final double maxLongitude;

  bool get isValid =>
      minLatitude.isFinite &&
      minLongitude.isFinite &&
      maxLatitude.isFinite &&
      maxLongitude.isFinite &&
      minLatitude >= -90 &&
      maxLatitude <= 90 &&
      minLatitude <= maxLatitude &&
      minLongitude >= -180 &&
      maxLongitude <= 180 &&
      minLongitude <= maxLongitude;
}

/// Completed tiles are retained up to [maxLoadedTiles] using least-recently-used
/// eviction. A failed tile is not marked as loaded, allowing the next map-idle
/// event to retry it.
final class DemandHeatmapViewportCoordinator<T> {
  DemandHeatmapViewportCoordinator({
    required this.loadTile,
    this.tileSizeDegrees = 0.05,
    this.maxLoadedTiles = defaultMaxLoadedTiles,
    this.maxTilesPerRefresh = defaultMaxTilesPerRefresh,
  }) : assert(tileSizeDegrees > 0),
       assert(maxLoadedTiles > 0),
       assert(maxTilesPerRefresh > 0);

  static const int defaultMaxLoadedTiles = 128;
  static const int defaultMaxTilesPerRefresh = 64;

  final DemandHeatmapTileLoader<T> loadTile;
  final double tileSizeDegrees;
  final int maxLoadedTiles;
  final int maxTilesPerRefresh;
  final Map<_HeatmapTile, List<T>> _loadedTiles = {};
  final Map<_HeatmapTile, Future<List<T>>> _inFlightTiles = {};
  int _generation = 0;

  Future<List<T>> refresh(MapViewportBounds viewport) async {
    if (!viewport.isValid) {
      throw ArgumentError.value(viewport, 'viewport', 'bounds are invalid');
    }

    final visibleTiles = _tilesFor(viewport);
    for (final tile in visibleTiles) {
      _touchTile(tile);
    }
    await Future.wait(visibleTiles.map(_loadIfNeeded));
    return [for (final tile in visibleTiles) ...?_loadedTiles[tile]];
  }

  void clear() {
    _generation++;
    _loadedTiles.clear();
    _inFlightTiles.clear();
  }

  Future<void> _loadIfNeeded(_HeatmapTile tile) async {
    if (_loadedTiles.containsKey(tile)) {
      _touchTile(tile);
      return;
    }
    final existingRequest = _inFlightTiles[tile];
    if (existingRequest != null) {
      await existingRequest;
      return;
    }

    final requestGeneration = _generation;
    final request = loadTile(tile.bounds(tileSizeDegrees));
    _inFlightTiles[tile] = request;
    try {
      final items = List<T>.unmodifiable(await request);
      if (requestGeneration == _generation) {
        _insertLoadedTile(tile, items);
      }
    } finally {
      if (identical(_inFlightTiles[tile], request)) {
        final _ = _inFlightTiles.remove(tile);
      }
    }
  }

  void _touchTile(_HeatmapTile tile) {
    final existing = _loadedTiles.remove(tile);
    if (existing != null) {
      _loadedTiles[tile] = existing;
    }
  }

  void _insertLoadedTile(_HeatmapTile tile, List<T> items) {
    _loadedTiles.remove(tile);
    _loadedTiles[tile] = items;
    while (_loadedTiles.length > maxLoadedTiles) {
      _loadedTiles.remove(_loadedTiles.keys.first);
    }
  }

  List<_HeatmapTile> _tilesFor(MapViewportBounds viewport) {
    var minLatitudeTile = _tileIndex(viewport.minLatitude);
    var maxLatitudeTile = _tileIndex(viewport.maxLatitude);
    var minLongitudeTile = _tileIndex(viewport.minLongitude);
    var maxLongitudeTile = _tileIndex(viewport.maxLongitude);

    final latSpan = maxLatitudeTile - minLatitudeTile + 1;
    final lngSpan = maxLongitudeTile - minLongitudeTile + 1;
    if (latSpan * lngSpan > maxTilesPerRefresh) {
      final sideLimit = math.max(1, math.sqrt(maxTilesPerRefresh).floor());
      final centerLat = (minLatitudeTile + maxLatitudeTile) ~/ 2;
      final centerLng = (minLongitudeTile + maxLongitudeTile) ~/ 2;
      final halfLat = sideLimit ~/ 2;
      final halfLng = (maxTilesPerRefresh ~/ sideLimit) ~/ 2;
      minLatitudeTile = math.max(minLatitudeTile, centerLat - halfLat);
      maxLatitudeTile = math.min(
        maxLatitudeTile,
        minLatitudeTile + sideLimit - 1,
      );
      final maxLngCount = math.max(
        1,
        maxTilesPerRefresh ~/ (maxLatitudeTile - minLatitudeTile + 1),
      );
      minLongitudeTile = math.max(minLongitudeTile, centerLng - halfLng);
      maxLongitudeTile = math.min(
        maxLongitudeTile,
        minLongitudeTile + maxLngCount - 1,
      );
    }

    final tiles = <_HeatmapTile>[];
    for (
      var latitude = minLatitudeTile;
      latitude <= maxLatitudeTile && tiles.length < maxTilesPerRefresh;
      latitude++
    ) {
      for (
        var longitude = minLongitudeTile;
        longitude <= maxLongitudeTile && tiles.length < maxTilesPerRefresh;
        longitude++
      ) {
        tiles.add(_HeatmapTile(latitude, longitude));
      }
    }
    return tiles;
  }

  int _tileIndex(double coordinate) => (coordinate / tileSizeDegrees).floor();
}

class const _HeatmapTile(this.latitudeIndex, this.longitudeIndex)
    extends Equatable {
  final int latitudeIndex;
  final int longitudeIndex;

  MapViewportBounds bounds(double tileSizeDegrees) {
    final minLatitude = _clampLatitude(latitudeIndex * tileSizeDegrees);
    final minLongitude = _clampLongitude(longitudeIndex * tileSizeDegrees);
    return MapViewportBounds(
      minLatitude: minLatitude,
      minLongitude: minLongitude,
      maxLatitude: _clampLatitude((latitudeIndex + 1) * tileSizeDegrees),
      maxLongitude: _clampLongitude((longitudeIndex + 1) * tileSizeDegrees),
    );
  }

  double _clampLatitude(double value) => value.clamp(-90.0, 90.0).toDouble();

  double _clampLongitude(double value) => value.clamp(-180.0, 180.0).toDouble();

  @override
  List<Object> get props => [latitudeIndex, longitudeIndex];
}

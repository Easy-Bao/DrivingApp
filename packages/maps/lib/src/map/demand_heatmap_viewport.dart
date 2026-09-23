typedef DemandHeatmapTileLoader<T> = Future<List<T>> Function(
  MapViewportBounds bounds,
);

/// The portion of the map for which demand cells are currently visible.
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

/// Loads demand cells by map zone so panning into a new zone triggers a fetch.
///
/// Completed tiles are retained for the lifetime of the coordinator. A failed
/// tile is not marked as loaded, allowing the next map-idle event to retry it.
final class DemandHeatmapViewportCoordinator<T> {
  DemandHeatmapViewportCoordinator({
    required this.loadTile,
    this.tileSizeDegrees = 0.05,
  }) : assert(tileSizeDegrees > 0);

  final DemandHeatmapTileLoader<T> loadTile;
  final double tileSizeDegrees;
  final Map<_HeatmapTile, List<T>> _loadedTiles = {};
  final Map<_HeatmapTile, Future<List<T>>> _inFlightTiles = {};

  Future<List<T>> refresh(MapViewportBounds viewport) async {
    if (!viewport.isValid) {
      throw ArgumentError.value(viewport, 'viewport', 'bounds are invalid');
    }

    final visibleTiles = _tilesFor(viewport);
    await Future.wait(visibleTiles.map(_loadIfNeeded));
    return [
      for (final tile in visibleTiles) ...?_loadedTiles[tile],
    ];
  }

  void clear() {
    _loadedTiles.clear();
    _inFlightTiles.clear();
  }

  Future<void> _loadIfNeeded(_HeatmapTile tile) async {
    if (_loadedTiles.containsKey(tile)) return;
    final existingRequest = _inFlightTiles[tile];
    if (existingRequest != null) {
      await existingRequest;
      return;
    }

    final request = loadTile(tile.bounds(tileSizeDegrees));
    _inFlightTiles[tile] = request;
    try {
      _loadedTiles[tile] = List<T>.unmodifiable(await request);
    } finally {
      _inFlightTiles.remove(tile);
    }
  }

  List<_HeatmapTile> _tilesFor(MapViewportBounds viewport) {
    final minLatitudeTile = _tileIndex(viewport.minLatitude);
    final maxLatitudeTile = _tileIndex(viewport.maxLatitude);
    final minLongitudeTile = _tileIndex(viewport.minLongitude);
    final maxLongitudeTile = _tileIndex(viewport.maxLongitude);
    final tiles = <_HeatmapTile>[];
    for (var latitude = minLatitudeTile;
        latitude <= maxLatitudeTile;
        latitude++) {
      for (var longitude = minLongitudeTile;
          longitude <= maxLongitudeTile;
          longitude++) {
        tiles.add(_HeatmapTile(latitude, longitude));
      }
    }
    return tiles;
  }

  int _tileIndex(double coordinate) => (coordinate / tileSizeDegrees).floor();
}

class const _HeatmapTile(this.latitudeIndex, this.longitudeIndex) {
  final int latitudeIndex;
  final int longitudeIndex;

  MapViewportBounds bounds(double tileSizeDegrees) {
    final minLatitude = latitudeIndex * tileSizeDegrees;
    final minLongitude = longitudeIndex * tileSizeDegrees;
    return MapViewportBounds(
      minLatitude: minLatitude,
      minLongitude: minLongitude,
      maxLatitude: _clampLatitude(minLatitude + tileSizeDegrees),
      maxLongitude: _clampLongitude(minLongitude + tileSizeDegrees),
    );
  }

  double _clampLatitude(double value) => value > 90 ? 90 : value;

  double _clampLongitude(double value) => value > 180 ? 180 : value;

  @override
  bool operator ==(Object other) =>
      other is _HeatmapTile &&
      other.latitudeIndex == latitudeIndex &&
      other.longitudeIndex == longitudeIndex;

  @override
  int get hashCode => Object.hash(latitudeIndex, longitudeIndex);
}

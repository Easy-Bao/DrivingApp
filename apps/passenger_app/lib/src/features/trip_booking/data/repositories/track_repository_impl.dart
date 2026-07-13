import 'package:core_models/core_models.dart';
import 'package:flutter/foundation.dart';
import 'package:location_service/location_service.dart';

/// Fetches road-snapped route coordinates via Mapbox. If the routing API is
/// unreachable or returns no data, falls back to a straight-line interpolation
/// between start and end so the map route layer always has something to render.
class TrackRepositoryImpl implements TrackRepository {
  @override
  Future<List<List<double>>?> getRoutePolyline({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final route = await MapProvider.getRoute(
        startLat,
        startLng,
        endLat,
        endLng,
      );
      if (route != null && route.polylinePoints.isNotEmpty) {
        return route.polylinePoints;
      }
      return _linearInterpolation(startLat, startLng, endLat, endLng);
    } catch (error) {
      debugPrint('TrackRepositoryImpl.getRoutePolyline failed: $error');
      return _linearInterpolation(startLat, startLng, endLat, endLng);
    }
  }

  /// Generates a 5-point straight-line interpolation when the routing API is unreachable.
  List<List<double>> _linearInterpolation(
    double startLat,
    double startLng,
    double endLat,
    double endLng, {
    int steps = 5,
  }) {
    final points = <List<double>>[];
    for (var index = 0; index <= steps; index++) {
      final t = index / steps;
      points.add([
        startLat + (endLat - startLat) * t,
        startLng + (endLng - startLng) * t,
      ]);
    }
    return points;
  }
}

import 'package:location_service/location_service.dart';
import 'package:core_models/core_models.dart';
import 'package:flutter/foundation.dart';

/// Track and route calculation repository adapter.
///
/// Fetches real-world road-snapped route coordinates using [MapProvider.getRoute].
///
/// **Lifecycle & Execution Flow:**
/// Route snapping begins when the presentation layer requests a snap-to-road polyline.
/// The repository delegates to [getRoutePolyline], which calls the Mapbox routing API.
/// If the lookup fails, a straight-line interpolation between start and end is returned
/// as a graceful fallback so the map route layer always has something to display.
class TrackRepositoryImpl implements TrackRepository {
  @override
  Future<List<List<double>>?> getRoutePolyline({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final route = await MapProvider.getRoute(startLat, startLng, endLat, endLng);
      if (route != null && route.polylinePoints.isNotEmpty) {
        return route.polylinePoints;
      }
      return _linearInterpolation(startLat, startLng, endLat, endLng);
    } catch (error) {
      debugPrint('TrackRepositoryImpl.getRoutePolyline failed: $error');
      return _linearInterpolation(startLat, startLng, endLat, endLng);
    }
  }

  /// Generates a 5-point straight-line interpolation between two coordinates when
  /// the routing API is unreachable or returns no data.
  List<List<double>> _linearInterpolation(
    double startLat,
    double startLng,
    double endLat,
    double endLng, {
    int steps = 5,
  }) {
    final points = <List<double>>[];
    for (var index = 0; i <= steps; i++) {
      final t = index / steps;
      points.add([
        startLat + (endLat - startLat) * t,
        startLng + (endLng - startLng) * t,
      ]);
    }
    return points;
  }
}

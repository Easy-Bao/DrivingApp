import 'package:BaoRide/src/rust/api/fare_api.dart' as fare_api;
import 'package:BaoRide/src/rust/models/fare_models.dart' as rust_fare;
import 'package:BaoRide/src/rust/models/route_models.dart' as rust_route;

abstract class RideRepository {
  Future<rust_fare.FareResult> getFare({
    required double distanceKm,
    required double durationMinutes,
  });

  Future<List<rust_fare.HeatmapCell>> getSurgeHeatmap({
    required double lat,
    required double lng,
    required int gridSize,
    required double cellSize,
    required List<double> requestLats,
    required List<double> requestLngs,
  });

  Future<rust_route.RouteSequenceResult> optimizeRoute({
    required double startLat,
    required double startLng,
    required List<rust_route.Waypoint> waypoints,
  });
}

class RideRepositoryImpl implements RideRepository {
  @override
  Future<rust_fare.FareResult> getFare({
    required double distanceKm,
    required double durationMinutes,
  }) {
    return fare_api.computeFareDefault(
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
    );
  }

  @override
  Future<List<rust_fare.HeatmapCell>> getSurgeHeatmap({
    required double lat,
    required double lng,
    required int gridSize,
    required double cellSize,
    required List<double> requestLats,
    required List<double> requestLngs,
  }) {
    return fare_api.calculateSurgeHeatmap(
      centerLat: lat,
      centerLng: lng,
      gridSize: gridSize,
      cellSizeDegrees: cellSize,
      requestLats: requestLats,
      requestLngs: requestLngs,
    );
  }

  @override
  Future<rust_route.RouteSequenceResult> optimizeRoute({
    required double startLat,
    required double startLng,
    required List<rust_route.Waypoint> waypoints,
  }) {
    return fare_api.calculateOptimalRoute(
      startLat: startLat,
      startLng: startLng,
      waypoints: waypoints,
    );
  }
}

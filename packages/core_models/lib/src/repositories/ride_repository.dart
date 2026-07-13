import '../models/fare_result.dart';
import '../models/waypoint.dart';
import '../models/route_sequence_result.dart';

/// Contract: defines the fare computation and route sequence optimization.
/// Decoupled from FFI-generated code by utilizing domain-specific pure Dart models.
abstract class RideRepository {
  /// Calculates the fare breakup for the given trip metrics.
  Future<FareResult> getFare({
    required double distanceKm,
    required double durationMinutes,
  });

  /// Calculates the optimal sequence to traverse a set of waypoints.
  Future<RouteSequenceResult> optimizeRoute({
    required double startLat,
    required double startLng,
    required List<Waypoint> waypoints,
  });
}

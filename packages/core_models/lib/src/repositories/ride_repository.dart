import 'package:fpdart/fpdart.dart';

import '../errors/failures.dart';
import '../models/fare_result.dart';
import '../models/waypoint.dart';
import '../models/route_sequence_result.dart';

/// Contract: defines the fare computation and route sequence optimization.
/// Decoupled from FFI-generated code by utilizing domain-specific pure Dart models.
abstract class RideRepository {
  /// Calculates the fare breakup for the given trip metrics.
  ///
  /// Returns [Right] with a [FareResult] breakdown or [Left] with a [Failure]
  /// on network errors or unparseable fare payload responses.
  Future<Either<Failure, FareResult>> getFare({
    required double distanceKm,
    required double durationMinutes,
  });

  /// Calculates the optimal sequence to traverse a set of waypoints.
  ///
  /// Returns [Right] with the optimized [RouteSequenceResult] or [Left] with a
  /// [Failure] if the route geometry cannot be resolved.
  Future<Either<Failure, RouteSequenceResult>> optimizeRoute({
    required double startLat,
    required double startLng,
    required List<Waypoint> waypoints,
  });
}

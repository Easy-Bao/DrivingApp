import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';

abstract class IRideRepository {
  Future<Either<Failure, FareResult>> getFare({
    required double distanceKm,
    required double durationMinutes,
  });

  Future<Either<Failure, RouteSequenceResult>> optimizeRoute({
    required double startLat,
    required double startLng,
    required List<Waypoint> waypoints,
  });
}

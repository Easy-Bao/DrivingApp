import 'package:fpdart/fpdart.dart';

import '../errors/failures.dart';
import '../models/fare_result_model.dart';
import '../models/waypoint_model.dart';
import '../models/route_sequence_result_model.dart';

abstract class RideRepository {

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

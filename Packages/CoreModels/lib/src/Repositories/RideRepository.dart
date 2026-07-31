import 'package:fpdart/fpdart.dart';

import '../Errors/Failures.dart';
import '../Models/FareResultModel.dart';
import '../Models/WaypointModel.dart';
import '../Models/RouteSequenceResultModel.dart';

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

import 'package:fpdart/fpdart.dart';
import 'package:shared_core/shared_core.dart';

abstract class IFareRepository {
  Future<Either<Failure, FareResult>> estimateFare({
    required double distanceKm,
    required double durationMinutes,
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  });
}

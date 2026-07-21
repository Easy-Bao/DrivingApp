import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';

abstract class TelemetryRepository {
  Future<Either<Failure, bool>> updateLocation({
    required String driverId,
    required double lat,
    required double lng,
  });

  Future<Either<Failure, Map<String, dynamic>>> fetchPassengerLocation(String rideId);
}

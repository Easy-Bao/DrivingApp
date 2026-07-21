import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';

abstract class TripRepository {
  Future<Either<Failure, List<dynamic>>> fetchTripHistory(String driverId);

  Future<Either<Failure, Map<String, dynamic>>> fetchStats(String driverId);

  Future<Either<Failure, Map<String, dynamic>>> getRideStatus(String rideId);

  Future<Either<Failure, bool>> acceptRide({
    required String rideId,
    required String driverId,
    required String driverName,
    required String driverRating,
    required String vehicleType,
    required String plateNumber,
  });

  Future<Either<Failure, bool>> updateRideStatus(String rideId, String status);
}

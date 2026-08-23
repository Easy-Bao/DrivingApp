import 'package:fpdart/fpdart.dart';
import 'package:shared_core/shared_core.dart';

abstract class IDriverRideRepository {
  Future<Either<Failure, void>> acceptRide({
    required String rideId,
    required String driverId,
  });

  Future<Either<Failure, void>> updateRideStatus({
    required String rideId,
    required RideStatus status,
  });

  Future<Either<Failure, RideSnapshot>> fetchRide(String rideId);

  Future<Either<Failure, int>> settleCash(String rideId);

  Future<Either<Failure, RideCounterparty>> fetchCounterparty(String rideId);

  Future<Either<Failure, (double latitude, double longitude)?>>
  fetchPassengerLocation(String rideId);

  Future<Either<Failure, void>> publishDriverLocation({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  });

  Future<Either<Failure, void>> clearDriverLocation();
}

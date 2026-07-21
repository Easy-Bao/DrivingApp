import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';

abstract class BiddingRepository {
  Future<Either<Failure, Map<String, dynamic>>> fetchFareEstimate({
    required double distanceKm,
    required double durationMinutes,
    String rideType = 'Solo Ride',
  });

  Future<Either<Failure, List<dynamic>>> fetchActiveBids(String driverId);

  Future<Either<Failure, bool>> placeBid({
    required String sessionId,
    required String driverId,
    required String driverName,
    required String plateNumber,
    required String vehicleType,
    double? proposedFare,
  });

  Future<Either<Failure, bool>> cancelBid({
    required String sessionId,
    required String driverId,
  });
}

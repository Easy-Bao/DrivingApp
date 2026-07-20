import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';

abstract class BiddingRepository {
  Future<Either<Failure, Map<String, dynamic>?>> openBidSession({
    required String passengerId,
    required String rideType,
    required double pickupLat,
    required double pickupLng,
    required String pickupName,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffName,
    required double distanceKm,
    required double durationMinutes,
    String? targetDriverId,
  });

  Future<Either<Failure, Map<String, dynamic>?>> getBidSession(String sessionId);

  Future<Either<Failure, List<dynamic>>> pollBidOffers(String sessionId);

  Future<Either<Failure, Map<String, dynamic>?>> acceptBidOffer({
    required String sessionId,
    required String offerId,
  });

  Future<Either<Failure, bool>> cancelBidSession(String sessionId);

  Future<Either<Failure, Map<String, dynamic>?>> fetchFareEstimate({
    required String rideType,
    required double distanceKm,
    required double durationMinutes,
  });
}

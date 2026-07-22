import 'package:core_models/core_models.dart';
import 'package:fare_services/src/features/fare/domain/entities/fare_estimate.dart';
import 'package:fpdart/fpdart.dart';

abstract class FareRepository {
  /// Fetches an authoritative binding fare quote from the backend service.
  /// Falls back to local estimation display if network is unavailable.
  Future<Either<Failure, FareEstimate>> getFareQuote({
    required double distanceKm,
    required double durationMinutes,
    String rideType = 'Solo Ride',
  });

  /// Computes a fallback fare estimate using active pricing rules.
  FareEstimate calculateFallbackFareEstimate({
    required double distanceKm,
    required double durationMinutes,
  });
}

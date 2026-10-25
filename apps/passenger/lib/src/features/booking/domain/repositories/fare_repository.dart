import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/booking/booking.dart';

abstract interface class FareRepository() {
  Future<Result<FareEstimate, Failure>> estimateFare({
    required double distanceKm,
    required double durationMinutes,
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  });
}

extension FareRepositoryResultApi on FareRepository {
  Future<Result<FareEstimate, DomainFailure>> estimateFareResult({
    required double distanceKm,
    required double durationMinutes,
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) => captureResult(
    () => estimateFare(
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      originLatitude: originLatitude,
      originLongitude: originLongitude,
      destinationLatitude: destinationLatitude,
      destinationLongitude: destinationLongitude,
    ),
    message: 'Fare calculation is temporarily unavailable.',
  );
}

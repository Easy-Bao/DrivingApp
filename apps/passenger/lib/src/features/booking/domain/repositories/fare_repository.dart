import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger/src/features/booking/booking.dart';

abstract interface class FareRepository() {
  Future<Either<Failure, FareEstimate>> estimateFare({
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
  }) => _captureFareResult(
    () => estimateFare(
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      originLatitude: originLatitude,
      originLongitude: originLongitude,
      destinationLatitude: destinationLatitude,
      destinationLongitude: destinationLongitude,
    ),
  );
}

Future<Result<T, DomainFailure>> _captureFareResult<T>(
  Future<Either<Failure, T>> Function() operation,
) async {
  try {
    final result = await operation();
    final Result<T, DomainFailure> converted = result
        .fold<Result<T, DomainFailure>>(
          (failure) => Err<T, DomainFailure>(failure),
          (value) => Ok<T, DomainFailure>(value),
        );
    return converted;
  } catch (error) {
    return Err<T, DomainFailure>(
      FailureMapper.fromException(
        error,
        serverMessage: 'Fare calculation is temporarily unavailable.',
      ),
    );
  }
}

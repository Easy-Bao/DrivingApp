import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/booking/booking.dart';

abstract interface class DriverRepository() {
  Future<Result<List<DriverModel>, Failure>> getNearbyDrivers({
    required double lat,
    required double lng,
  });
}

extension DriverRepositoryResultApi on DriverRepository {
  Future<Result<List<DriverModel>, DomainFailure>> getNearbyDriversResult({
    required double lat,
    required double lng,
  }) => _captureDriverResult(() => getNearbyDrivers(lat: lat, lng: lng));
}

Future<Result<T, DomainFailure>> _captureDriverResult<T>(
  Future<Result<T, Failure>> Function() operation,
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
        serverMessage:
            'Driver availability is temporarily unavailable. Please try again.',
      ),
    );
  }
}

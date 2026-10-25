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
  }) => captureResult(
    () => getNearbyDrivers(lat: lat, lng: lng),
    message:
        'Driver availability is temporarily unavailable. Please try again.',
  );
}

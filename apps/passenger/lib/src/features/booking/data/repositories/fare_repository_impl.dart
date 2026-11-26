import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/booking/booking.dart';
import 'package:passenger/src/features/booking/data/datasources/fare_remote_data_source.dart';
import 'package:passenger/src/features/booking/data/repositories/booking_failure_mapper.dart';
import 'package:passenger/src/features/booking/domain/repositories/fare_repository.dart';

final class FareRepositoryImpl({required this._remoteDataSource})
    implements FareRepository {
  final FareRemoteDataSource _remoteDataSource;

  @override
  Future<Result<FareEstimate, Failure>> estimateFare({
    required double distanceKm,
    required double durationMinutes,
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    if (!_validCoordinate(originLatitude, originLongitude) ||
        !_validCoordinate(destinationLatitude, destinationLongitude) ||
        !distanceKm.isFinite ||
        distanceKm <= 0 ||
        !durationMinutes.isFinite ||
        durationMinutes <= 0) {
      return const Err(ValidationFailure('The trip route is invalid.'));
    }
    try {
      final fare = await _remoteDataSource.fetchEstimate(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        originLatitude: originLatitude,
        originLongitude: originLongitude,
        destinationLatitude: destinationLatitude,
        destinationLongitude: destinationLongitude,
      );
      if (!fare.totalFare.isFinite || fare.totalFare <= 0) {
        return const Err(ValidationFailure('The fare response is invalid.'));
      }
      return Ok(fare);
    } catch (error) {
      return Err(
        mapBookingFailure(
          error,
          permissionMessage: 'Fare calculation is unavailable.',
          timeoutMessage: 'Fare request timed out.',
          networkMessage: 'Unable to calculate fare. Check your connection.',
          serverMessage: 'Fare calculation is unavailable.',
          validationFailure: const RouteCalculationFailure(),
          handleAuth: false,
        ),
      );
    }
  }
}

bool _validCoordinate(double latitude, double longitude) {
  return latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

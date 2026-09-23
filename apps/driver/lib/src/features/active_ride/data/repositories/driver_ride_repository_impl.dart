import 'package:driver/src/features/active_ride/active_ride.dart';
import 'package:driver/src/features/auth/domain/failures/auth_failures.dart';
import 'package:dio/dio.dart';
import 'package:driver/src/features/active_ride/data/data_sources/ride_counterparty_remote_data_source.dart';
import 'package:driver/src/features/active_ride/data/data_sources/ride_remote_data_source.dart';
import 'package:driver/src/features/active_ride/data/data_sources/telemetry_remote_data_source.dart';
import 'package:driver/src/features/active_ride/domain/repositories/driver_ride_repository.dart';
import 'package:foundation/foundation.dart';
import 'package:driver/src/infrastructure/telemetry/driver_location_spool.dart';

final class DriverRideRepositoryImpl({
  required this._rideDataSource,
  required this._counterpartyDataSource,
  required this._telemetryDataSource,
  this._locationSpool,
}) implements DriverRideRepository {
  final RideRemoteDataSource _rideDataSource;
  final RideCounterpartyRemoteDataSource _counterpartyDataSource;
  final TelemetryRemoteDataSource _telemetryDataSource;
  final DriverLocationSpool? _locationSpool;

  @override
  Future<Result<void, Failure>> acceptRide({
    required String rideId,
    required String driverId,
  }) async {
    try {
      final accepted = await _rideDataSource.acceptRide(
        tripId: rideId,
        driverId: driverId,
      );
      return accepted
          ? const Ok(null)
          : const Err(ServerFailure('The ride could not be accepted.'));
    } catch (error) {
      return Err(_mapFailure(error, action: 'accept this ride'));
    }
  }

  @override
  Future<Result<void, Failure>> updateRideStatus({
    required String rideId,
    required RideStatus status,
  }) async {
    try {
      final updated = await _rideDataSource.updateRideStatus(
        tripId: rideId,
        status: status.value,
      );
      return updated
          ? const Ok(null)
          : const Err(ServerFailure('The ride status was not updated.'));
    } catch (error) {
      return Err(_mapFailure(error, action: 'update this ride'));
    }
  }

  @override
  Future<Result<RideSnapshot, Failure>> fetchRide(String rideId) async {
    try {
      final data = await _rideDataSource.getRideStatus(rideId);
      final ride = RideDto.fromJson(data, fallbackId: rideId).toDomain();
      if (ride.id.isEmpty || ride.status.isEmpty) {
        return const Err(ValidationFailure('The ride response is incomplete.'));
      }
      return Ok(ride);
    } catch (error) {
      return Err(_mapFailure(error, action: 'load this ride'));
    }
  }

  @override
  Future<Result<int, Failure>> settleCash(String rideId) async {
    try {
      final data = await _rideDataSource.settleCash(rideId);
      final fareAmount = SafeParse.toNullableDouble(data['fare_amount']);
      if (fareAmount == null || fareAmount <= 0) {
        return const Err(
          ValidationFailure('The settled ride has no payable fare.'),
        );
      }
      return Ok(fareAmount.round());
    } catch (error) {
      return Err(_mapFailure(error, action: 'settle this cash ride'));
    }
  }

  @override
  Future<Result<RideCounterparty, Failure>> fetchCounterparty(
    String rideId,
  ) async {
    try {
      return Ok(
        RideCounterparty.fromJson(await _counterpartyDataSource.fetch(rideId)),
      );
    } catch (error) {
      return Err(_mapFailure(error, action: 'load passenger contact details'));
    }
  }

  @override
  Future<Result<(double latitude, double longitude)?, Failure>>
  fetchPassengerLocation(String rideId) async {
    try {
      final data = await _telemetryDataSource.fetchPassengerLocation(rideId);
      final latitude = SafeParse.toNullableDouble(data['lat']);
      final longitude = SafeParse.toNullableDouble(data['lng']);
      if (latitude == null || longitude == null) return const Ok(null);
      return Ok((latitude, longitude));
    } catch (error) {
      return Err(_mapFailure(error, action: 'load passenger location'));
    }
  }

  @override
  Future<Result<void, Failure>> publishDriverLocation({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  }) async {
    try {
      final spool = _locationSpool;
      if (spool == null) {
        final sent = await _telemetryDataSource.sendLocationUpdate(
          lat: latitude,
          lng: longitude,
          heading: heading,
          speed: speed,
        );
        return sent
            ? const Ok(null)
            : const Err(NetworkFailure('Driver location was not accepted.'));
      }
      await spool.enqueue(
        DriverLocationPoint(
          latitude: latitude,
          longitude: longitude,
          observedAt: DateTime.now().toUtc(),
          heading: heading,
          speed: speed,
        ),
      );
      await spool.flush(
        (point) => _telemetryDataSource.sendLocationUpdate(
          lat: point.latitude,
          lng: point.longitude,
          observedAt: point.observedAt,
          heading: point.heading,
          speed: point.speed,
        ),
      );
      return const Ok(null);
    } catch (error) {
      if (error is DioException &&
          NetworkAvailabilityCoordinator.isNetworkFailure(error)) {
        return const Ok(null);
      }
      return Err(_mapFailure(error, action: 'share driver location'));
    }
  }

  @override
  Future<Result<void, Failure>> clearDriverLocation() async {
    try {
      final removed = await _telemetryDataSource.removeLocation();
      return removed
          ? const Ok(null)
          : const Err(ServerFailure('Driver location was not removed.'));
    } catch (error) {
      return Err(_mapFailure(error, action: 'remove driver location'));
    }
  }
}

Failure _mapFailure(Object error, {required String action}) {
  if (error is Failure) return error;
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return const AuthFailure('Your driver session has ended. Sign in again.');
    }
    if (statusCode == 400 || statusCode == 404 || statusCode == 422) {
      return ValidationFailure('Unable to $action with the supplied ride.');
    }
    if (statusCode == null) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return const ServerFailure.withStatusCode(
          'The ride request timed out.',
          504,
        );
      }
      return NetworkFailure('Unable to $action. Check your connection.');
    }
    return ServerFailure.withStatusCode(
      'Unable to $action right now.',
      statusCode,
    );
  }
  if (error is ServerException) {
    return FailureMapper.fromException(
      error,
      serverMessage: 'Unable to $action right now.',
      validationMessage: 'Unable to $action with the supplied ride.',
    );
  }
  if (error is FormatException || error is DataParsingException) {
    return ValidationFailure('Unable to $action because the data is invalid.');
  }
  return ServerFailure('Unable to $action right now.');
}

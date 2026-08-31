import 'package:auth/auth.dart';
import 'package:ride/ride.dart';
import 'package:dio/dio.dart';
import 'package:driver_app/src/features/trip/data/data_sources/ride_counterparty_remote_data_source.dart';
import 'package:driver_app/src/features/trip/data/data_sources/ride_remote_data_source.dart';
import 'package:driver_app/src/features/trip/data/data_sources/telemetry_remote_data_source.dart';
import 'package:driver_app/src/features/trip/domain/repositories/i_driver_ride_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_core/shared_core.dart';

class DriverRideRepository implements IDriverRideRepository {
  DriverRideRepository({
    required RideRemoteDataSource rideDataSource,
    required RideCounterpartyRemoteDataSource counterpartyDataSource,
    required TelemetryRemoteDataSource telemetryDataSource,
  }) : _rideDataSource = rideDataSource,
       _counterpartyDataSource = counterpartyDataSource,
       _telemetryDataSource = telemetryDataSource;

  final RideRemoteDataSource _rideDataSource;
  final RideCounterpartyRemoteDataSource _counterpartyDataSource;
  final TelemetryRemoteDataSource _telemetryDataSource;

  @override
  Future<Either<Failure, void>> acceptRide({
    required String rideId,
    required String driverId,
  }) async {
    try {
      final accepted = await _rideDataSource.acceptRide(
        tripId: rideId,
        driverId: driverId,
      );
      return accepted
          ? const Right(null)
          : const Left(ServerFailure('The ride could not be accepted.'));
    } catch (error) {
      return Left(_mapFailure(error, action: 'accept this ride'));
    }
  }

  @override
  Future<Either<Failure, void>> updateRideStatus({
    required String rideId,
    required RideStatus status,
  }) async {
    try {
      final updated = await _rideDataSource.updateRideStatus(
        tripId: rideId,
        status: status.value,
      );
      return updated
          ? const Right(null)
          : const Left(ServerFailure('The ride status was not updated.'));
    } catch (error) {
      return Left(_mapFailure(error, action: 'update this ride'));
    }
  }

  @override
  Future<Either<Failure, RideSnapshot>> fetchRide(String rideId) async {
    try {
      final data = await _rideDataSource.getRideStatus(rideId);
      final ride = RideDto.fromJson(data, fallbackId: rideId).toDomain();
      if (ride.id.isEmpty || ride.status.isEmpty) {
        return const Left(
          ValidationFailure('The ride response is incomplete.'),
        );
      }
      return Right(ride);
    } catch (error) {
      return Left(_mapFailure(error, action: 'load this ride'));
    }
  }

  @override
  Future<Either<Failure, int>> settleCash(String rideId) async {
    try {
      final data = await _rideDataSource.settleCash(rideId);
      final fareCentavos = SafeParse.toNullableDouble(data['fare_centavos']);
      if (fareCentavos == null || fareCentavos <= 0) {
        return const Left(
          ValidationFailure('The settled ride has no payable fare.'),
        );
      }
      return Right(fareCentavos.round());
    } catch (error) {
      return Left(_mapFailure(error, action: 'settle this cash ride'));
    }
  }

  @override
  Future<Either<Failure, RideCounterparty>> fetchCounterparty(
    String rideId,
  ) async {
    try {
      return Right(
        RideCounterparty.fromJson(await _counterpartyDataSource.fetch(rideId)),
      );
    } catch (error) {
      return Left(_mapFailure(error, action: 'load passenger contact details'));
    }
  }

  @override
  Future<Either<Failure, (double latitude, double longitude)?>>
  fetchPassengerLocation(String rideId) async {
    try {
      final data = await _telemetryDataSource.fetchPassengerLocation(rideId);
      final latitude = SafeParse.toNullableDouble(data['lat']);
      final longitude = SafeParse.toNullableDouble(data['lng']);
      if (latitude == null || longitude == null) return const Right(null);
      return Right((latitude, longitude));
    } catch (error) {
      return Left(_mapFailure(error, action: 'load passenger location'));
    }
  }

  @override
  Future<Either<Failure, void>> publishDriverLocation({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  }) async {
    try {
      final sent = await _telemetryDataSource.sendLocationUpdate(
        lat: latitude,
        lng: longitude,
        heading: heading,
        speed: speed,
      );
      return sent
          ? const Right(null)
          : const Left(NetworkFailure('Driver location was not accepted.'));
    } catch (error) {
      return Left(_mapFailure(error, action: 'share driver location'));
    }
  }

  @override
  Future<Either<Failure, void>> clearDriverLocation() async {
    try {
      final removed = await _telemetryDataSource.removeLocation();
      return removed
          ? const Right(null)
          : const Left(ServerFailure('Driver location was not removed.'));
    } catch (error) {
      return Left(_mapFailure(error, action: 'remove driver location'));
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

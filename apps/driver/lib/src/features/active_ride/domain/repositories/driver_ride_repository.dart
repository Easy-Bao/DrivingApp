import 'package:driver/src/features/active_ride/active_ride.dart';
import 'package:fpdart/fpdart.dart';
import 'package:foundation/foundation.dart';

abstract interface class DriverRideRepository {
  Future<Either<Failure, void>> acceptRide({
    required String rideId,
    required String driverId,
  });

  Future<Either<Failure, void>> updateRideStatus({
    required String rideId,
    required RideStatus status,
  });

  Future<Either<Failure, RideSnapshot>> fetchRide(String rideId);

  Future<Either<Failure, int>> settleCash(String rideId);

  Future<Either<Failure, RideCounterparty>> fetchCounterparty(String rideId);

  Future<Either<Failure, (double latitude, double longitude)?>>
  fetchPassengerLocation(String rideId);

  Future<Either<Failure, void>> publishDriverLocation({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  });

  Future<Either<Failure, void>> clearDriverLocation();
}

extension DriverRideRepositoryResultAdapters on DriverRideRepository {
  Future<Result<void, DomainFailure>> acceptRideResult({
    required String rideId,
    required String driverId,
  }) {
    return _captureResult(
      acceptRide(rideId: rideId, driverId: driverId),
      message: 'Unable to accept this ride right now.',
    );
  }

  Future<Result<void, DomainFailure>> updateRideStatusResult({
    required String rideId,
    required RideStatus status,
  }) {
    return _captureResult(
      updateRideStatus(rideId: rideId, status: status),
      message: 'Unable to update this ride right now.',
    );
  }

  Future<Result<RideSnapshot, DomainFailure>> fetchRideResult(String rideId) {
    return _captureResult(
      fetchRide(rideId),
      message: 'Unable to load this ride right now.',
    );
  }

  Future<Result<int, DomainFailure>> settleCashResult(String rideId) {
    return _captureResult(
      settleCash(rideId),
      message: 'Unable to settle this cash ride right now.',
    );
  }

  Future<Result<void, DomainFailure>> publishDriverLocationResult({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  }) {
    return _captureResult(
      publishDriverLocation(
        latitude: latitude,
        longitude: longitude,
        heading: heading,
        speed: speed,
      ),
      message: 'Unable to share driver location right now.',
    );
  }
}

Future<Result<T, DomainFailure>> _captureResult<T>(
  Future<Either<Failure, T>> operation, {
  required String message,
}) async {
  try {
    final result = await operation;
    return await result.fold(
      (failure) => Err<T, DomainFailure>(failure),
      (value) => Ok<T, DomainFailure>(value),
    );
  } catch (error) {
    return Err<T, DomainFailure>(
      FailureMapper.fromException(error, serverMessage: message),
    );
  }
}

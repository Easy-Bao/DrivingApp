import 'package:driver/src/features/active_ride/active_ride.dart';
import 'package:foundation/foundation.dart';

abstract interface class DriverRideRepository {
  Future<Result<void, Failure>> acceptRide({
    required String rideId,
    required String driverId,
  });

  Future<Result<void, Failure>> updateRideStatus({
    required String rideId,
    required RideStatus status,
  });

  Future<Result<RideSnapshot, Failure>> fetchRide(String rideId);

  Future<Result<int, Failure>> settleCash(String rideId);

  Future<Result<RideCounterparty, Failure>> fetchCounterparty(String rideId);

  Future<Result<(double latitude, double longitude)?, Failure>>
  fetchPassengerLocation(String rideId);

  Future<Result<void, Failure>> publishDriverLocation({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  });

  Future<Result<void, Failure>> clearDriverLocation();
}

extension DriverRideRepositoryResultAdapters on DriverRideRepository {
  Future<Result<void, DomainFailure>> acceptRideResult({
    required String rideId,
    required String driverId,
  }) {
    return _captureResult(
      () => acceptRide(rideId: rideId, driverId: driverId),
      message: 'Unable to accept this ride right now.',
    );
  }

  Future<Result<void, DomainFailure>> updateRideStatusResult({
    required String rideId,
    required RideStatus status,
  }) {
    return _captureResult(
      () => updateRideStatus(rideId: rideId, status: status),
      message: 'Unable to update this ride right now.',
    );
  }

  Future<Result<RideSnapshot, DomainFailure>> fetchRideResult(String rideId) {
    return _captureResult(
      () => fetchRide(rideId),
      message: 'Unable to load this ride right now.',
    );
  }

  Future<Result<int, DomainFailure>> settleCashResult(String rideId) {
    return _captureResult(
      () => settleCash(rideId),
      message: 'Unable to settle this cash ride right now.',
    );
  }

  Future<Result<RideCounterparty, DomainFailure>> fetchCounterpartyResult(
    String rideId,
  ) {
    return _captureResult(
      () => fetchCounterparty(rideId),
      message: 'Unable to load passenger contact details right now.',
    );
  }

  Future<Result<(double latitude, double longitude)?, DomainFailure>>
  fetchPassengerLocationResult(String rideId) {
    return _captureResult(
      () => fetchPassengerLocation(rideId),
      message: 'Unable to load passenger location right now.',
    );
  }

  Future<Result<void, DomainFailure>> publishDriverLocationResult({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  }) {
    return _captureResult(
      () => publishDriverLocation(
        latitude: latitude,
        longitude: longitude,
        heading: heading,
        speed: speed,
      ),
      message: 'Unable to share driver location right now.',
    );
  }

  Future<Result<void, DomainFailure>> clearDriverLocationResult() {
    return _captureResult(
      clearDriverLocation,
      message: 'Unable to remove driver location right now.',
    );
  }
}

Future<Result<T, DomainFailure>> _captureResult<T>(
  Future<Result<T, Failure>> Function() operation, {
  required String message,
}) async {
  try {
    final result = await operation();
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

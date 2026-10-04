import 'package:driver/src/features/active_ride/active_ride.dart';
import 'package:foundation/foundation.dart';

abstract interface class DriverRideRepository {
  Future<Result<void, Failure>> acceptRide({
    required String rideId,
    required String driverId,
  });

  Future<Result<RideSnapshot, Failure>> markArrived({
    required String rideId,
    required double latitude,
    required double longitude,
  });

  Future<Result<RideSnapshot, Failure>> startRide({
    required String rideId,
    required double latitude,
    required double longitude,
  });

  Future<Result<RideSnapshot, Failure>> completeRide({
    required String rideId,
    required double latitude,
    required double longitude,
  });

  Future<Result<RideSnapshot, Failure>> markPassengerNoShow(String rideId);

  Future<Result<RideSnapshot, Failure>> cancelRide({
    required String rideId,
    required String reason,
    String details = '',
  });

  Future<Result<RideSnapshot, Failure>> emergencyStop({
    required String rideId,
    required String reason,
    String details = '',
  });

  Future<Result<void, Failure>> createSafetyReport({
    required String rideId,
    required String category,
    required String description,
  });

  Future<Result<RideSnapshot, Failure>> fetchRide(String rideId);

  Future<Result<int, Failure>> settleCash({
    required String rideId,
    required int cashReceivedAmount,
    required int cashChangeAmount,
    required String cashOutcome,
  });

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

  Future<Result<RideSnapshot, DomainFailure>> markArrivedResult({
    required String rideId,
    required double latitude,
    required double longitude,
  }) {
    return _captureResult(
      () =>
          markArrived(rideId: rideId, latitude: latitude, longitude: longitude),
      message: 'Unable to confirm arrival at the pickup point.',
    );
  }

  Future<Result<RideSnapshot, DomainFailure>> markPassengerNoShowResult(
    String rideId,
  ) {
    return _captureResult(
      () => markPassengerNoShow(rideId),
      message: 'Unable to record the passenger no-show.',
    );
  }

  Future<Result<void, DomainFailure>> createSafetyReportResult({
    required String rideId,
    required String category,
    required String description,
  }) {
    return _captureResult(
      () => createSafetyReport(
        rideId: rideId,
        category: category,
        description: description,
      ),
      message: 'Unable to submit the safety report right now.',
    );
  }

  Future<Result<RideSnapshot, DomainFailure>> cancelRideResult({
    required String rideId,
    required String reason,
    String details = '',
  }) {
    return _captureResult(
      () => cancelRide(rideId: rideId, reason: reason, details: details),
      message: 'Unable to cancel this ride right now.',
    );
  }

  Future<Result<RideSnapshot, DomainFailure>> emergencyStopResult({
    required String rideId,
    required String reason,
    String details = '',
  }) {
    return _captureResult(
      () => emergencyStop(rideId: rideId, reason: reason, details: details),
      message: 'Unable to end this ride for safety right now.',
    );
  }

  Future<Result<RideSnapshot, DomainFailure>> startRideResult({
    required String rideId,
    required double latitude,
    required double longitude,
  }) {
    return _captureResult(
      () => startRide(rideId: rideId, latitude: latitude, longitude: longitude),
      message: 'Unable to start this trip right now.',
    );
  }

  Future<Result<RideSnapshot, DomainFailure>> completeRideResult({
    required String rideId,
    required double latitude,
    required double longitude,
  }) {
    return _captureResult(
      () => completeRide(
        rideId: rideId,
        latitude: latitude,
        longitude: longitude,
      ),
      message: 'Unable to complete this trip right now.',
    );
  }

  Future<Result<RideSnapshot, DomainFailure>> fetchRideResult(String rideId) {
    return _captureResult(
      () => fetchRide(rideId),
      message: 'Unable to load this ride right now.',
    );
  }

  Future<Result<int, DomainFailure>> settleCashResult({
    required String rideId,
    required int cashReceivedAmount,
    required int cashChangeAmount,
    required String cashOutcome,
  }) {
    return _captureResult(
      () => settleCash(
        rideId: rideId,
        cashReceivedAmount: cashReceivedAmount,
        cashChangeAmount: cashChangeAmount,
        cashOutcome: cashOutcome,
      ),
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

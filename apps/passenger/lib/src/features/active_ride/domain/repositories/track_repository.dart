import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';

abstract interface class TrackRepository {
  Future<List<List<double>>?> getRoutePolyline({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  });

  Future<Result<RideUpdate, Failure>> getRideStatusUpdate(String rideId);

  Future<Result<RideSnapshot, Failure>> fetchRide(String rideId);

  Future<Result<RideCounterparty, Failure>> fetchCounterparty(String rideId);

  Future<Result<DriverLocation, Failure>> fetchDriverLocation(String rideId);

  Future<Result<void, Failure>> updateRideStatus(
    String rideId,
    RideStatus status,
  );

  Future<Result<void, Failure>> cancelRide({
    required String rideId,
    required String reason,
    String details = '',
  });

  Future<Result<void, Failure>> emergencyStop({
    required String rideId,
    required String reason,
    String details = '',
  });

  Future<Result<void, Failure>> createSafetyReport({
    required String rideId,
    required String category,
    required String description,
  });

  Future<Result<void, Failure>> publishPassengerLocation({
    required String rideId,
    required double latitude,
    required double longitude,
  });
}

extension TrackRepositoryResultAdapters on TrackRepository {
  Future<Result<RideUpdate, DomainFailure>> getRideStatusResult(
    String rideId,
  ) => captureResult(
    () => getRideStatusUpdate(rideId),
    message: 'Ride status is temporarily unavailable. Please try again.',
  );

  Future<Result<RideSnapshot, DomainFailure>> fetchRideResult(String rideId) =>
      captureResult(
        () => fetchRide(rideId),
        message: 'Ride details are temporarily unavailable.',
      );

  Future<Result<RideCounterparty, DomainFailure>> fetchCounterpartyResult(
    String rideId,
  ) => captureResult(
    () => fetchCounterparty(rideId),
    message: 'Driver contact details are temporarily unavailable.',
  );

  Future<Result<DriverLocation, DomainFailure>> fetchDriverLocationResult(
    String rideId,
  ) => captureResult(
    () => fetchDriverLocation(rideId),
    message: 'Driver location is temporarily unavailable. Please try again.',
  );

  Future<Result<void, DomainFailure>> cancelRideResult({
    required String rideId,
    required String reason,
    String details = '',
  }) => captureResult(
    () => cancelRide(rideId: rideId, reason: reason, details: details),
    message: 'The ride could not be cancelled. Please try again.',
  );

  Future<Result<void, DomainFailure>> emergencyStopResult({
    required String rideId,
    required String reason,
    String details = '',
  }) => captureResult(
    () => emergencyStop(rideId: rideId, reason: reason, details: details),
    message: 'The ride could not be ended for safety. Please try again.',
  );

  Future<Result<void, DomainFailure>> publishPassengerLocationResult({
    required String rideId,
    required double latitude,
    required double longitude,
  }) => captureResult(
    () => publishPassengerLocation(
      rideId: rideId,
      latitude: latitude,
      longitude: longitude,
    ),
    message: 'Unable to share your current trip location.',
  );

  Future<Result<void, DomainFailure>> createSafetyReportResult({
    required String rideId,
    required String category,
    required String description,
  }) => captureResult(
    () => createSafetyReport(
      rideId: rideId,
      category: category,
      description: description,
    ),
    message: 'Unable to submit the safety report right now.',
  );
}

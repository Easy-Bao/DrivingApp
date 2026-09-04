import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';

abstract interface class TrackRepository {
  Future<List<List<double>>?> getRoutePolyline({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  });

  Future<Either<Failure, RideUpdate>> getRideStatusUpdate(String rideId);

  Future<Either<Failure, RideSnapshot>> fetchRide(String rideId);

  Future<Either<Failure, RideCounterparty>> fetchCounterparty(String rideId);

  Future<Either<Failure, (double latitude, double longitude)>>
  fetchDriverLocation(String rideId);

  Future<Either<Failure, void>> updateRideStatus(
    String rideId,
    RideStatus status,
  );

  Future<Either<Failure, void>> publishPassengerLocation({
    required String rideId,
    required double latitude,
    required double longitude,
  });
}

extension TrackRepositoryResultAdapters on TrackRepository {
  /// Converts the legacy repository contract into the strict result used by
  /// active-trip synchronization without changing existing implementations.
  Future<Result<RideUpdate, DomainFailure>> getRideStatusResult(
    String rideId,
  ) async {
    try {
      final result = await getRideStatusUpdate(rideId);
      return await result.fold(
        (failure) => Err<RideUpdate, DomainFailure>(failure),
        (value) => Ok<RideUpdate, DomainFailure>(value),
      );
    } catch (error) {
      return Err<RideUpdate, DomainFailure>(
        FailureMapper.fromException(
          error,
          serverMessage:
              'Ride status is temporarily unavailable. Please try again.',
        ),
      );
    }
  }

  Future<Result<RideSnapshot, DomainFailure>> fetchRideResult(
    String rideId,
  ) async {
    try {
      final result = await fetchRide(rideId);
      final Result<RideSnapshot, DomainFailure> converted = result
          .fold<Result<RideSnapshot, DomainFailure>>(
            (failure) => Err<RideSnapshot, DomainFailure>(failure),
            (value) => Ok<RideSnapshot, DomainFailure>(value),
          );
      return converted;
    } catch (error) {
      return Err<RideSnapshot, DomainFailure>(
        FailureMapper.fromException(
          error,
          serverMessage: 'Ride details are temporarily unavailable.',
        ),
      );
    }
  }

  Future<Result<RideCounterparty, DomainFailure>> fetchCounterpartyResult(
    String rideId,
  ) async {
    try {
      final result = await fetchCounterparty(rideId);
      final Result<RideCounterparty, DomainFailure> converted = result
          .fold<Result<RideCounterparty, DomainFailure>>(
            (failure) => Err<RideCounterparty, DomainFailure>(failure),
            (value) => Ok<RideCounterparty, DomainFailure>(value),
          );
      return converted;
    } catch (error) {
      return Err<RideCounterparty, DomainFailure>(
        FailureMapper.fromException(
          error,
          serverMessage: 'Driver contact details are temporarily unavailable.',
        ),
      );
    }
  }

  /// Converts the legacy location contract into a strict domain result so a
  /// telemetry gap cannot surface as an untyped exception in the UI layer.
  Future<Result<(double latitude, double longitude), DomainFailure>>
  fetchDriverLocationResult(String rideId) async {
    try {
      final result = await fetchDriverLocation(rideId);
      return await result.fold(
        (failure) =>
            Err<(double latitude, double longitude), DomainFailure>(failure),
        (value) =>
            Ok<(double latitude, double longitude), DomainFailure>(value),
      );
    } catch (error) {
      return Err<(double latitude, double longitude), DomainFailure>(
        FailureMapper.fromException(
          error,
          serverMessage:
              'Driver location is temporarily unavailable. Please try again.',
        ),
      );
    }
  }

  Future<Result<void, DomainFailure>> updateRideStatusResult(
    String rideId,
    RideStatus status,
  ) async {
    try {
      final result = await updateRideStatus(rideId, status);
      return await result.fold(
        (failure) => Err<void, DomainFailure>(failure),
        (_) => const Ok<void, DomainFailure>(null),
      );
    } catch (error) {
      return Err<void, DomainFailure>(
        FailureMapper.fromException(
          error,
          serverMessage:
              'The ride status could not be updated. Please try again.',
        ),
      );
    }
  }

  Future<Result<void, DomainFailure>> publishPassengerLocationResult({
    required String rideId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final result = await publishPassengerLocation(
        rideId: rideId,
        latitude: latitude,
        longitude: longitude,
      );
      final Result<void, DomainFailure> converted = result
          .fold<Result<void, DomainFailure>>(
            (failure) => Err<void, DomainFailure>(failure),
            (_) => const Ok<void, DomainFailure>(null),
          );
      return converted;
    } catch (error) {
      return Err<void, DomainFailure>(
        FailureMapper.fromException(
          error,
          serverMessage: 'Unable to share your current trip location.',
        ),
      );
    }
  }
}

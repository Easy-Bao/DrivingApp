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
}

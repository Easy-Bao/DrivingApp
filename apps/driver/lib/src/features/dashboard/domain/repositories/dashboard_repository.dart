import 'package:driver/src/features/active_ride/active_ride.dart';
import 'package:foundation/foundation.dart';
import 'package:driver/src/features/dashboard/domain/entities/driver_dashboard_stats.dart';
import 'package:driver/src/features/dashboard/domain/entities/driver_dispatch_snapshot.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class DashboardRepository {
  Future<Either<Failure, bool>> getPersistedOnlineStatus();

  Future<Either<Failure, void>> updateOnlineStatus({
    required bool isOnline,
    required double lat,
    required double lng,
  });

  Future<Either<Failure, DriverDashboardStats>> getDashboardStats();

  Future<Either<Failure, DriverDispatchSnapshot>> getDispatchSnapshot({
    bool includeOffers = true,
    int limit = 10,
  });

  Future<Either<Failure, void>> submitRideOffer({
    required String sessionId,
    required double farePesos,
  });

  Future<Either<Failure, RideSnapshot>> fetchRide(String rideId);
}

extension DashboardRepositoryResultApi on DashboardRepository {
  Future<Result<bool, DomainFailure>> getPersistedOnlineStatusResult() {
    return _captureDashboardResult(
      getPersistedOnlineStatus,
      message: 'Unable to restore driver availability right now.',
    );
  }

  Future<Result<void, DomainFailure>> updateOnlineStatusResult({
    required bool isOnline,
    required double lat,
    required double lng,
  }) {
    return _captureDashboardResult(
      () => updateOnlineStatus(isOnline: isOnline, lat: lat, lng: lng),
      message: 'Unable to update driver availability right now.',
    );
  }

  Future<Result<DriverDashboardStats, DomainFailure>>
  getDashboardStatsResult() {
    return _captureDashboardResult(
      getDashboardStats,
      message: 'Unable to load driver dashboard statistics right now.',
    );
  }

  Future<Result<DriverDispatchSnapshot, DomainFailure>>
  getDispatchSnapshotResult({bool includeOffers = true, int limit = 10}) {
    return _captureDashboardResult(
      () => getDispatchSnapshot(includeOffers: includeOffers, limit: limit),
      message: 'Unable to load driver dispatch data right now.',
    );
  }

  Future<Result<void, DomainFailure>> submitRideOfferResult({
    required String sessionId,
    required double farePesos,
  }) {
    return _captureDashboardResult(
      () => submitRideOffer(sessionId: sessionId, farePesos: farePesos),
      message: 'Unable to submit this ride offer right now.',
    );
  }

  Future<Result<RideSnapshot, DomainFailure>> fetchRideResult(String rideId) {
    return _captureDashboardResult(
      () => fetchRide(rideId),
      message: 'Unable to load this ride right now.',
    );
  }
}

Future<Result<T, DomainFailure>> _captureDashboardResult<T>(
  Future<Either<Failure, T>> Function() operation, {
  required String message,
}) async {
  try {
    final result = await operation();
    final Result<T, DomainFailure> converted = result
        .fold<Result<T, DomainFailure>>(
          (failure) => Err<T, DomainFailure>(failure),
          (value) => Ok<T, DomainFailure>(value),
        );
    return converted;
  } catch (error) {
    return Err<T, DomainFailure>(
      FailureMapper.fromException(error, serverMessage: message),
    );
  }
}

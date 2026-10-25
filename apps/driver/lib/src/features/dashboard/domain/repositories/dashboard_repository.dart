import 'package:driver/src/features/active_ride/active_ride.dart';
import 'package:foundation/foundation.dart';
import 'package:driver/src/features/dashboard/domain/entities/driver_dashboard_stats.dart';
import 'package:driver/src/features/dashboard/domain/entities/driver_dispatch_snapshot.dart';

abstract interface class DashboardRepository {
  Future<Result<bool, Failure>> getPersistedOnlineStatus();

  Future<Result<void, Failure>> updateOnlineStatus({
    required bool isOnline,
    required double lat,
    required double lng,
  });

  Future<Result<DashboardStats, Failure>> getDashboardStats();

  Future<Result<DispatchSnapshot, Failure>> getDispatchSnapshot({
    bool includeOffers = true,
    int limit = 10,
  });

  Future<Result<void, Failure>> submitRideOffer({
    required String sessionId,
    required double farePesos,
  });

  Future<Result<RideSnapshot, Failure>> fetchRide(String rideId);

  Future<Result<void, Failure>> declineRideRequest(String sessionId);
}

extension DashboardRepositoryResultApi on DashboardRepository {
  Future<Result<bool, DomainFailure>> getPersistedOnlineStatusResult() {
    return captureResult(
      getPersistedOnlineStatus,
      message: 'Unable to restore driver availability right now.',
    );
  }

  Future<Result<void, DomainFailure>> updateOnlineStatusResult({
    required bool isOnline,
    required double lat,
    required double lng,
  }) {
    return captureResult(
      () => updateOnlineStatus(isOnline: isOnline, lat: lat, lng: lng),
      message: 'Unable to update driver availability right now.',
    );
  }

  Future<Result<DashboardStats, DomainFailure>> getDashboardStatsResult() {
    return captureResult(
      getDashboardStats,
      message: 'Unable to load driver dashboard statistics right now.',
    );
  }

  Future<Result<DispatchSnapshot, DomainFailure>> getDispatchSnapshotResult({
    bool includeOffers = true,
    int limit = 10,
  }) {
    return captureResult(
      () => getDispatchSnapshot(includeOffers: includeOffers, limit: limit),
      message: 'Unable to load driver dispatch data right now.',
    );
  }

  Future<Result<void, DomainFailure>> submitRideOfferResult({
    required String sessionId,
    required double farePesos,
  }) {
    return captureResult(
      () => submitRideOffer(sessionId: sessionId, farePesos: farePesos),
      message: 'Unable to submit this ride offer right now.',
    );
  }

  Future<Result<void, DomainFailure>> declineRideRequestResult(
    String sessionId,
  ) => captureResult(
    () => declineRideRequest(sessionId),
    message: 'Unable to decline this ride request. Please try again.',
  );

  Future<Result<RideSnapshot, DomainFailure>> fetchRideResult(String rideId) {
    return captureResult(
      () => fetchRide(rideId),
      message: 'Unable to load this ride right now.',
    );
  }
}

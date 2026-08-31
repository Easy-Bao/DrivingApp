import 'package:driver_app/src/features/active_ride/active_ride.dart';
import 'package:foundation/foundation.dart';
import 'package:driver_app/src/features/home/domain/entities/driver_dashboard_stats.dart';
import 'package:driver_app/src/features/home/domain/entities/driver_dispatch_snapshot.dart';
import 'package:fpdart/fpdart.dart';

abstract class IDashboardRepository {
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

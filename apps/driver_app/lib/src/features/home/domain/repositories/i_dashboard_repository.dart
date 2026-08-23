import 'package:shared_core/shared_core.dart';
import 'package:driver_app/src/features/home/domain/entities/driver_dashboard_stats.dart';
import 'package:fpdart/fpdart.dart';

abstract class IDashboardRepository {
  Future<Either<Failure, bool>> getPersistedOnlineStatus();

  Future<Either<Failure, void>> updateOnlineStatus({
    required bool isOnline,
    required double lat,
    required double lng,
  });

  Future<Either<Failure, DriverDashboardStats>> getDashboardStats();
}

import 'package:driver_app/src/features/activity/domain/entities/driver_activity_stats.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_core/shared_core.dart';

abstract class IDriverActivityRepository {
  Future<Either<Failure, DriverActivityStats>> fetchStats(String driverId);

  Future<Either<Failure, OffsetPage<Map<String, dynamic>>>> fetchTripHistory(
    String driverId, {
    int limit = 25,
    int offset = 0,
    bool activeOnly = false,
  });

  Future<Either<Failure, Map<String, dynamic>>> fetchEarningsSummary(
    String driverId,
  );
}

import 'package:driver/src/features/performance/domain/entities/driver_performance_stats.dart';
import 'package:foundation/foundation.dart';

abstract interface class DriverPerformanceRepository {
  Future<Result<DriverPerformanceStats, Failure>> fetchStats(String driverId);
}

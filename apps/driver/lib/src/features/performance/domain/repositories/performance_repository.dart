import 'package:driver/src/features/performance/domain/entities/performance_stats.dart';
import 'package:foundation/foundation.dart';

abstract interface class PerformanceRepository {
  Future<Result<PerformanceStats, Failure>> fetchStats(String driverId);
}

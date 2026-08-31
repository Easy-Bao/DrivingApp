import 'package:driver_app/src/features/performance/domain/entities/driver_performance_stats.dart';
import 'package:fpdart/fpdart.dart';
import 'package:foundation/foundation.dart';

abstract interface class DriverPerformanceRepository {
  Future<Either<Failure, DriverPerformanceStats>> fetchStats(String driverId);
}

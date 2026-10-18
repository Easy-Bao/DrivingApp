import 'package:driver/src/features/earnings/domain/entities/driver_earnings_summary.dart';
import 'package:foundation/foundation.dart';

abstract interface class DriverEarningsRepository {
  Future<Result<DriverEarningsSummary, Failure>> fetchEarningsSummary(
    String driverId,
  );
}

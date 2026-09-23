import 'package:foundation/foundation.dart';

abstract interface class DriverEarningsRepository {
  Future<Result<Map<String, dynamic>, Failure>> fetchEarningsSummary(
    String driverId,
  );
}

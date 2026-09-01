import 'package:fpdart/fpdart.dart';
import 'package:foundation/foundation.dart';

abstract interface class DriverEarningsRepository {
  Future<Either<Failure, Map<String, dynamic>>> fetchEarningsSummary(
    String driverId,
  );
}

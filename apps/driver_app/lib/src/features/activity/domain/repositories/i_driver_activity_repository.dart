import 'package:shared_core/shared_core.dart';
import 'package:fpdart/fpdart.dart';

abstract class IDriverActivityRepository {
  Future<Either<Failure, OffsetPage<Map<String, dynamic>>>> fetchTripHistory(
    String driverId, {
    int limit = 25,
    int offset = 0,
  });

  Future<Either<Failure, Map<String, dynamic>>> fetchEarningsSummary(
    String driverId,
  );
}

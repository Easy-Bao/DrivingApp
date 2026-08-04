import 'package:fpdart/fpdart.dart';
import 'package:shared_core/shared_core.dart';

abstract class IActivityRepository {
  Future<Either<Failure, List<RideHistoryModel>>> fetchRideHistory(
    String passengerId,
  );
}

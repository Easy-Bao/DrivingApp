import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';

abstract class IActivityRepository {
  Future<Either<Failure, List<RideHistoryModel>>> fetchRideHistory(
    String passengerId,
  );
}

import 'package:core_models/CoreModels.dart';
import 'package:fpdart/fpdart.dart';

abstract class IActivityRepository {
  Future<Either<Failure, List<RideHistoryModel>>> fetchRideHistory(
    String passengerId,
  );
}

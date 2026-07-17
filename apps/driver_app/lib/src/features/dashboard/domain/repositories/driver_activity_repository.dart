import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';

abstract class DriverActivityRepository {
  Future<Either<Failure, List<dynamic>>> fetchTripHistory(String driverId);
}

import 'package:core_models/CoreModels.dart';
import 'package:fpdart/fpdart.dart';

abstract class IDriverActivityRepository {
  Future<Either<Failure, List<dynamic>>> fetchTripHistory(String driverId);
}

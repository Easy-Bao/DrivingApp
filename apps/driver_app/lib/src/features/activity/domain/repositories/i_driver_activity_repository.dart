import 'package:shared_core/shared_core.dart';
import 'package:fpdart/fpdart.dart';

abstract class IDriverActivityRepository {
  Future<Either<Failure, List<dynamic>>> fetchTripHistory(String driverId);
}

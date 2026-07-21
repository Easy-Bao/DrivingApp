import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';

abstract class PassengerRepository {
  Future<Either<Failure, Map<String, dynamic>>> fetchPassengerProfile(String passengerId);
}

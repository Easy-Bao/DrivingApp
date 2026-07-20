import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';

abstract class PassengerProfileRepository {
  Future<Either<Failure, Map<String, dynamic>>> getPassengerProfile(String passengerId);

  Future<Either<Failure, Map<String, dynamic>>> updateProfile({
    required String id,
    required String name,
    required String phone,
    required String email,
  });

  Future<Either<Failure, List<dynamic>>> fetchRideHistory(String passengerId);

  Future<Either<Failure, List<dynamic>>> fetchNotifications(String passengerId);
}

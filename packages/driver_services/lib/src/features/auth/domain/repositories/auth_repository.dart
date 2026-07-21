import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';

abstract class AuthRepository {
  Future<Either<Failure, Map<String, dynamic>>> authenticateDriver({
    required String email,
    required String password,
  });

  Future<Either<Failure, Map<String, dynamic>>> fetchProfile(String driverId);
}

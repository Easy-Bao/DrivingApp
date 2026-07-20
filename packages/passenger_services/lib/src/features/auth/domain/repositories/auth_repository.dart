import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';

abstract class AuthRepository {
  Future<Either<Failure, Map<String, dynamic>>> loginPassenger({
    required String email,
    required String password,
  });

  Future<Either<Failure, Map<String, dynamic>>> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<Either<Failure, bool>> verifyOtp({
    required String email,
    required String code,
  });

  Future<Either<Failure, bool>> forgotPassword({
    required String email,
  });
}

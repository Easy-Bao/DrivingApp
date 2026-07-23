import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/auth/domain/entities/auth_credentials.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthCredentials>> authenticatePassenger({
    required String email,
    required String password,
  });

  Future<Either<Failure, Map<String, dynamic>>> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<Either<Failure, AuthCredentials>> verifyOtp({
    required String email,
    required String code,
    required String password,
  });

  Future<Either<Failure, void>> resetPassword({
    required String email,
  });

  Future<Either<Failure, void>> confirmResetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
}

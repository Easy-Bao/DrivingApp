import 'package:core_models/CoreModels.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/Features/Auth/Domain/Entities/AuthCredentials.dart';

abstract class IAuthRepository {
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

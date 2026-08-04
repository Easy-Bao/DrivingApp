import 'package:shared_core/shared_core.dart';
import 'package:driver_app/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:fpdart/fpdart.dart';

abstract class IAuthRepository {
  Future<Either<Failure, AuthCredentials>> authenticateDriver({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> resetPassword({required String email});
}

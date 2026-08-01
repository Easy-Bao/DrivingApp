import 'package:core_models/CoreModels.dart';
import 'package:driver_app/src/Features/Auth/Domain/Entities/AuthCredentials.dart';
import 'package:fpdart/fpdart.dart';

abstract class IAuthRepository {
  Future<Either<Failure, AuthCredentials>> authenticateDriver({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> resetPassword({
    required String email,
  });
}

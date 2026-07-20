import 'package:core_models/core_models.dart';
import 'package:driver_app/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:driver_app/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class SignInUseCase {
  final AuthRepository _authRepository;

  SignInUseCase(this._authRepository);

  Future<Either<Failure, AuthCredentials>> execute({
    required String email,
    required String password,
  }) {
    return _authRepository.authenticateDriver(
      email: email,
      password: password,
    );
  }
}

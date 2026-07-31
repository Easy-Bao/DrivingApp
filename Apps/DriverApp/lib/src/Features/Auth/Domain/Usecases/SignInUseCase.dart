import 'package:core_models/core_models.dart';
import 'package:driver_app/src/Features/Auth/Domain/Entities/AuthCredentials.dart';
import 'package:driver_app/src/Features/Auth/Domain/Repositories/AuthRepository.dart';
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

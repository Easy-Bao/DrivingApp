import 'package:core_models/CoreModels.dart';
import 'package:driver_app/src/Features/Auth/Domain/Entities/AuthCredentials.dart';
import 'package:driver_app/src/Features/Auth/Domain/Repositories/IAuthRepository.dart';
import 'package:fpdart/fpdart.dart';

class SignInUseCase {
  final IAuthRepository _authRepository;

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

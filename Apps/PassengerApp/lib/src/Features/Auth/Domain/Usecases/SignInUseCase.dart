import 'package:core_models/CoreModels.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/Features/Auth/Domain/Entities/AuthCredentials.dart';
import 'package:passenger_app/src/Features/Auth/Domain/Repositories/IAuthRepository.dart';

class SignInUseCase {
  final IAuthRepository _authRepository;

  SignInUseCase(this._authRepository);

  Future<Either<Failure, AuthCredentials>> execute({
    required String email,
    required String password,
  }) {
    return _authRepository.authenticatePassenger(
      email: email,
      password: password,
    );
  }
}

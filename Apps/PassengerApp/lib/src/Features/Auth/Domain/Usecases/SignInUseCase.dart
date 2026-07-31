import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/Features/Auth/Domain/Entities/AuthCredentials.dart';
import 'package:passenger_app/src/Features/Auth/Domain/Repositories/AuthRepository.dart';

class SignInUseCase {
  final AuthRepository _authRepository;

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

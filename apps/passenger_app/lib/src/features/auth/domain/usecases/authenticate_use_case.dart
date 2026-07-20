import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/auth_repository.dart';

class AuthenticateUseCase {
  final AuthRepository _authRepository;

  AuthenticateUseCase(this._authRepository);

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

import 'package:driver_app/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:driver_app/src/features/auth/domain/repositories/driver_auth_repository.dart';
import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';

class SignInUseCase {
  final DriverAuthRepository _authRepository;

  SignInUseCase(this._authRepository);

  Future<Either<Failure, DriverAuthCredentials>> execute({
    required String email,
    required String password,
  }) {
    return _authRepository.authenticate(email: email, password: password);
  }
}

import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/passenger_auth_repository.dart';

class SignInUseCase {
  final PassengerAuthRepository _authRepository;

  SignInUseCase(this._authRepository);

  Future<Either<Failure, PassengerAuthCredentials>> execute({
    required String email,
    required String password,
  }) {
    return _authRepository.authenticate(email: email, password: password);
  }
}

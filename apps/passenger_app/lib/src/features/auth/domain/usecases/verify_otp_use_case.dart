import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:shared_core/shared_core.dart';

class VerifyOtpUseCase {
  final IAuthRepository _authRepository;

  VerifyOtpUseCase(this._authRepository);

  Future<Either<Failure, AuthCredentials>> execute({
    required String email,
    required String code,
    required String password,
  }) {
    return _authRepository.verifyOtp(
      email: email,
      code: code,
      password: password,
    );
  }
}

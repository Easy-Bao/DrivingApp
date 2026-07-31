import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/Features/Auth/Domain/Entities/AuthCredentials.dart';
import 'package:passenger_app/src/Features/Auth/Domain/Repositories/AuthRepository.dart';

class VerifyOtpUseCase {
  final AuthRepository _authRepository;

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

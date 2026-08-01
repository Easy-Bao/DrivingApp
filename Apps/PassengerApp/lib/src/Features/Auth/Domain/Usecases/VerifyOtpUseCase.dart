import 'package:core_models/CoreModels.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/Features/Auth/Domain/Entities/AuthCredentials.dart';
import 'package:passenger_app/src/Features/Auth/Domain/Repositories/IAuthRepository.dart';

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

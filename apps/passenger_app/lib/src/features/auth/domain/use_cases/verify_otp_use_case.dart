import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/passenger_auth_repository.dart';

class VerifyOtpUseCase {
  final PassengerAuthRepository _authRepository;

  VerifyOtpUseCase(this._authRepository);

  Future<Either<Failure, PassengerAuthCredentials>> execute({
    required String email,
    required String code,
  }) {
    return _authRepository.verifyOtp(email: email, code: code);
  }
}

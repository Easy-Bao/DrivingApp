import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/passenger_auth_repository.dart';

class ResendOtpUseCase {
  final PassengerAuthRepository _authRepository;

  ResendOtpUseCase(this._authRepository);

  Future<Either<Failure, void>> execute({required String email}) {
    return _authRepository.requestVerificationCode(email: email);
  }
}

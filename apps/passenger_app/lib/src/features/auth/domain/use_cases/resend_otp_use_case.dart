import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:shared_core/shared_core.dart';

class ResendOtpUseCase {
  final IAuthRepository _authRepository;

  ResendOtpUseCase(this._authRepository);

  Future<Either<Failure, void>> execute({required String email}) {
    return _authRepository.requestVerificationCode(email: email);
  }
}

import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:shared_core/shared_core.dart';

class ConfirmResetPasswordUseCase {
  final IAuthRepository _authRepository;

  ConfirmResetPasswordUseCase(this._authRepository);

  Future<Either<Failure, void>> execute({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return _authRepository.confirmResetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );
  }
}

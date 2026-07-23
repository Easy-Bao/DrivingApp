import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/auth_repository.dart';

class ConfirmResetPasswordUseCase {
  final AuthRepository _authRepository;

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

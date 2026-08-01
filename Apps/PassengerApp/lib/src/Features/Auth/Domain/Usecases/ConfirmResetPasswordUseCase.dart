import 'package:core_models/CoreModels.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/Features/Auth/Domain/Repositories/IAuthRepository.dart';

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

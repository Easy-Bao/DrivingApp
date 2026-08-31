import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/passenger_auth_repository.dart';

class ConfirmResetPasswordUseCase {
  final PassengerAuthRepository _authRepository;

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

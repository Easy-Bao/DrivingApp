import 'package:driver_app/src/features/auth/domain/repositories/driver_auth_repository.dart';
import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';

class ResetPasswordUseCase {
  final DriverAuthRepository _authRepository;

  ResetPasswordUseCase(this._authRepository);

  Future<Either<Failure, void>> execute({required String email}) {
    return _authRepository.resetPassword(email: email);
  }
}

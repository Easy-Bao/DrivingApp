import 'package:core_models/core_models.dart';
import 'package:driver_app/src/Features/Auth/Domain/Repositories/AuthRepository.dart';
import 'package:fpdart/fpdart.dart';

class ResetPasswordUseCase {
  final AuthRepository _authRepository;

  ResetPasswordUseCase(this._authRepository);

  Future<Either<Failure, void>> execute({required String email}) {
    return _authRepository.resetPassword(email: email);
  }
}

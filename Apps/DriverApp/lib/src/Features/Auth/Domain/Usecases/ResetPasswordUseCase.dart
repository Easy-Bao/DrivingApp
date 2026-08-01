import 'package:core_models/CoreModels.dart';
import 'package:driver_app/src/Features/Auth/Domain/Repositories/IAuthRepository.dart';
import 'package:fpdart/fpdart.dart';

class ResetPasswordUseCase {
  final IAuthRepository _authRepository;

  ResetPasswordUseCase(this._authRepository);

  Future<Either<Failure, void>> execute({required String email}) {
    return _authRepository.resetPassword(email: email);
  }
}

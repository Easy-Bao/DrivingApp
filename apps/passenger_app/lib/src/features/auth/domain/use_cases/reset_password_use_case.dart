import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/passenger_auth_repository.dart';

class ResetPasswordUseCase {
  final PassengerAuthRepository _authRepository;

  ResetPasswordUseCase(this._authRepository);

  Future<Either<Failure, void>> execute({required String email}) {
    return _authRepository.resetPassword(email: email);
  }
}

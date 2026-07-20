import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _authRepository;

  RegisterUseCase(this._authRepository);

  Future<Either<Failure, Map<String, dynamic>>> execute({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) {
    return _authRepository.registerPassenger(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
  }
}

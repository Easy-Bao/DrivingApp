import 'package:core_models/CoreModels.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/Features/Auth/Domain/Repositories/IAuthRepository.dart';

class RegisterUseCase {
  final IAuthRepository _authRepository;

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

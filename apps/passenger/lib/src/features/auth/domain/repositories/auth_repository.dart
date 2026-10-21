import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/auth/domain/entities/auth_credentials.dart';

abstract interface class AuthRepository {
  Future<Result<AuthCredentials, Failure>> authenticate({
    required String email,
    required String password,
    bool rememberMe = false,
  });

  Future<Result<Map<String, dynamic>, Failure>> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<Result<AuthCredentials, Failure>> verifyOtp({
    required String email,
    required String code,
  });

  Future<Result<void, Failure>> requestVerificationCode({
    required String email,
  });

  Future<Result<void, Failure>> resetPassword({required String email});

  Future<Result<void, Failure>> confirmResetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
}

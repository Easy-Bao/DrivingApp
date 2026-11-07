import 'package:foundation/foundation.dart';
import 'package:driver/src/features/auth/domain/entities/auth_credentials.dart';

abstract interface class AuthRepository {
  Future<Result<AuthCredentials, Failure>> authenticate({
    required String email,
    required String password,
  });

  /// Sends a verification code to [email].
  Future<Result<void, Failure>> resetPassword({required String email});

  /// Completes the reset with the emailed [code].
  Future<Result<void, Failure>> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  });
}

import 'package:foundation/foundation.dart';
import 'package:driver/src/features/auth/domain/entities/auth_credentials.dart';

abstract interface class DriverAuthRepository {
  Future<Result<DriverAuthCredentials, Failure>> authenticate({
    required String email,
    required String password,
  });

  Future<Result<void, Failure>> resetPassword({required String email});
}

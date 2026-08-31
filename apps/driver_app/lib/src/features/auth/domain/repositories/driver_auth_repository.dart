import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:driver_app/src/features/auth/domain/entities/auth_credentials.dart';

abstract interface class DriverAuthRepository {
  Future<Either<Failure, DriverAuthCredentials>> authenticate({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> resetPassword({required String email});
}

import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/auth/domain/entities/auth_credentials.dart';

abstract interface class PassengerAuthRepository {
  Future<Either<Failure, PassengerAuthCredentials>> authenticate({
    required String email,
    required String password,
  });

  Future<Either<Failure, Map<String, dynamic>>> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<Either<Failure, PassengerAuthCredentials>> verifyOtp({
    required String email,
    required String code,
  });

  Future<Either<Failure, void>> requestVerificationCode({
    required String email,
  });

  Future<Either<Failure, void>> resetPassword({required String email});

  Future<Either<Failure, void>> confirmResetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
}

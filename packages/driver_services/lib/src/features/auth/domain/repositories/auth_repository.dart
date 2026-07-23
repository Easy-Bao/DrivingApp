import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';

abstract class AuthRepository {
  Future<Either<Failure, Map<String, dynamic>>> authenticateDriver({
    required String email,
    required String password,
  });

  Future<Either<Failure, Map<String, dynamic>>> registerDriver({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String vehicleType,
    required String plateNumber,
  });

  Future<Either<Failure, bool>> verifyOtp({
    required String email,
    required String code,
  });

  Future<Either<Failure, bool>> forgotPassword({
    required String email,
  });

  Future<Either<Failure, Map<String, dynamic>>> fetchProfile(String driverId);
}

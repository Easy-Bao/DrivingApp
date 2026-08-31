import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class AuthRepository<TCredentials> {
  Future<Either<Failure, TCredentials>> authenticate({
    required String email,
    required String password,
  });

  Future<Either<Failure, void>> resetPassword({required String email});
}

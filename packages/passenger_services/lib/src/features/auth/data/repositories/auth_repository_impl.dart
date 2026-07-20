import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_services/src/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:passenger_services/src/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, Map<String, dynamic>>> loginPassenger({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.loginPassenger(
        email: email,
        password: password,
      );
      return Right(response);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> registerPassenger({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.registerPassenger(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      return Right(response);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyOtp({
    required String email,
    required String code,
  }) async {
    try {
      final result = await _remoteDataSource.verifyOtp(
        email: email,
        code: code,
      );
      return Right(result);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> forgotPassword({
    required String email,
  }) async {
    try {
      final result = await _remoteDataSource.forgotPassword(
        email: email,
      );
      return Right(result);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }
}

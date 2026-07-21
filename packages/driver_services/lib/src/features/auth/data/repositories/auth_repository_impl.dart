import 'package:core_models/core_models.dart';
import 'package:driver_services/src/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:driver_services/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, Map<String, dynamic>>> authenticateDriver({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _remoteDataSource.authenticateDriver(
        email: email,
        password: password,
      );
      return Right(result);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> fetchProfile(String driverId) async {
    try {
      final result = await _remoteDataSource.fetchProfile(driverId);
      return Right(result);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }
}

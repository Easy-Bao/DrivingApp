import 'package:core_models/core_models.dart';
import 'package:driver_services/src/features/auth/data/datasources/auth_remote_data_source.dart';
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
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> registerDriver({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String vehicleType,
    required String plateNumber,
  }) async {
    try {
      final result = await _remoteDataSource.registerDriver(
        name: name,
        email: email,
        phone: phone,
        password: password,
        vehicleType: vehicleType,
        plateNumber: plateNumber,
      );
      return Right(result);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (_) {
      return const Left(ServerFailure());
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
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> forgotPassword({
    required String email,
  }) async {
    try {
      final result = await _remoteDataSource.forgotPassword(email: email);
      return Right(result);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> fetchProfile(String driverId) async {
    try {
      final result = await _remoteDataSource.fetchProfile(driverId);
      return Right(result);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}

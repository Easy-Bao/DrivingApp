import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_services/src/features/passenger_profile/data/datasources/passenger_remote_datasource.dart';
import 'package:passenger_services/src/features/passenger_profile/domain/repositories/passenger_profile_repository.dart';

class PassengerProfileRepositoryImpl implements PassengerProfileRepository {
  final PassengerRemoteDataSource _remoteDataSource;

  PassengerProfileRepositoryImpl({required PassengerRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, Map<String, dynamic>>> getPassengerProfile(String passengerId) async {
    try {
      final profile = await _remoteDataSource.getPassengerProfile(passengerId);
      return Right(profile);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> updateProfile({
    required String id,
    required String name,
    required String phone,
    required String email,
  }) async {
    try {
      final updated = await _remoteDataSource.updateProfile(
        id: id,
        name: name,
        phone: phone,
        email: email,
      );
      return Right(updated);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> fetchRideHistory(String passengerId) async {
    try {
      final history = await _remoteDataSource.fetchRideHistory(passengerId);
      return Right(history);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> fetchNotifications(String passengerId) async {
    try {
      final notifications = await _remoteDataSource.fetchNotifications(passengerId);
      return Right(notifications);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }
}

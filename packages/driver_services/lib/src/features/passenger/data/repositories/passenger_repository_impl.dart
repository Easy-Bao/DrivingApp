import 'package:core_models/core_models.dart';
import 'package:driver_services/src/features/passenger/data/datasources/passenger_remote_datasource.dart';
import 'package:driver_services/src/features/passenger/domain/repositories/passenger_repository.dart';
import 'package:fpdart/fpdart.dart';

class PassengerRepositoryImpl implements PassengerRepository {
  final PassengerRemoteDataSource _remoteDataSource;

  PassengerRepositoryImpl({required PassengerRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, Map<String, dynamic>>> fetchPassengerProfile(String passengerId) async {
    try {
      final result = await _remoteDataSource.fetchPassengerProfile(passengerId);
      return Right(result);
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }
}

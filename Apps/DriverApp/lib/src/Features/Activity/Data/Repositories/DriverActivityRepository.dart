import 'package:core_models/CoreModels.dart';
import 'package:driver_app/src/Features/Activity/Domain/Repositories/IDriverActivityRepository.dart';
import 'package:driver_app/src/Features/Trip/Data/DataSources/TripRemoteDataSource.dart';
import 'package:fpdart/fpdart.dart';

class DriverActivityRepository implements IDriverActivityRepository {
  final TripRemoteDataSource _remoteDataSource;

  DriverActivityRepository({required TripRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  Failure _mapExceptionToFailure(Object error) {
    if (error is ServerException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return const AuthFailure(
          'Session expired or unauthorized. Please sign in again.',
        );
      }
      if (error.statusCode == 400 || error.statusCode == 422) {
        return const ValidationFailure('Invalid request data.');
      }
      return ServerFailure(error.message);
    }
    if (error is DataParsingException) {
      return ValidationFailure(error.message);
    }
    if (error is CacheException) {
      return CacheFailure(error.message);
    }
    return ServerFailure('Unexpected system error: $error');
  }

  @override
  Future<Either<Failure, List<dynamic>>> fetchTripHistory(
    String driverId,
  ) async {
    try {
      return Right(await _remoteDataSource.fetchTripHistory(driverId));
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }
}

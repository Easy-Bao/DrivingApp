import 'package:shared_core/shared_core.dart';
import 'package:driver_app/src/features/activity/data/datasources/driver_activity_remote_data_source.dart';
import 'package:driver_app/src/features/activity/domain/repositories/i_driver_activity_repository.dart';
import 'package:fpdart/fpdart.dart';

class DriverActivityRepository implements IDriverActivityRepository {
  final DriverActivityRemoteDataSource _remoteDataSource;

  DriverActivityRepository({
    required DriverActivityRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

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
      return const ServerFailure(
        'Driver trip history is temporarily unavailable. Please try again.',
      );
    }
    if (error is DataParsingException) {
      return ValidationFailure(error.message);
    }
    if (error is CacheException) {
      return CacheFailure(error.message);
    }
    return const ServerFailure(
      'Driver trip history is temporarily unavailable. Please try again.',
    );
  }

  @override
  Future<Either<Failure, OffsetPage<Map<String, dynamic>>>> fetchTripHistory(
    String driverId, {
    int limit = 25,
    int offset = 0,
  }) async {
    try {
      return Right(
        await _remoteDataSource.fetchTripHistory(
          driverId,
          limit: limit,
          offset: offset,
        ),
      );
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> fetchEarningsSummary(
    String driverId,
  ) async {
    try {
      return Right(await _remoteDataSource.fetchEarningsSummary(driverId));
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }
}

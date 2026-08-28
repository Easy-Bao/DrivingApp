import 'package:dio/dio.dart';
import 'package:driver_app/src/features/activity/data/datasources/driver_activity_remote_data_source.dart';
import 'package:driver_app/src/features/activity/domain/entities/driver_activity_stats.dart';
import 'package:driver_app/src/features/activity/domain/repositories/i_driver_activity_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_core/shared_core.dart';

class DriverActivityRepository implements IDriverActivityRepository {
  final DriverActivityRemoteDataSource _remoteDataSource;

  DriverActivityRepository({
    required DriverActivityRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  Failure _mapExceptionToFailure(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == null && _isTimeout(error.type)) {
        return const ServerFailure.withStatusCode(
          'Driver activity request timed out. Please try again.',
          504,
        );
      }
      if (statusCode == null) {
        return const NetworkFailure(
          'Unable to reach driver activity services. Check your connection and try again.',
        );
      }
      return FailureMapper.fromException(
        error,
        serverMessage:
            'Driver trip history is temporarily unavailable. Please try again.',
        validationMessage: 'Invalid driver activity request.',
        networkMessage:
            'Unable to reach driver activity services. Check your connection and try again.',
      );
    }
    if (error is ServerException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return const AuthFailure(
          'Session expired or unauthorized. Please sign in again.',
        );
      }
      if (error.statusCode == 400 || error.statusCode == 422) {
        return const ValidationFailure('Invalid request data.');
      }
      if (error.statusCode == 0) {
        return const NetworkFailure(
          'Unable to reach driver activity services. Check your connection and try again.',
        );
      }
      return ServerFailure.withStatusCode(
        'Driver trip history is temporarily unavailable. Please try again.',
        error.statusCode,
      );
    }
    if (error is DataParsingException) {
      return const ValidationFailure(
        'Driver activity data is invalid. Please try again.',
      );
    }
    if (error is CacheException) {
      return FailureMapper.fromException(error);
    }
    return const ServerFailure(
      'Driver trip history is temporarily unavailable. Please try again.',
    );
  }

  bool _isTimeout(DioExceptionType type) => switch (type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => true,
    _ => false,
  };

  @override
  Future<Either<Failure, DriverActivityStats>> fetchStats(
    String driverId,
  ) async {
    try {
      final values = await _remoteDataSource.fetchStats(driverId);
      return Right(
        DriverActivityStats(
          todayEarningsCentavos: _readNonNegativeInt(
            values,
            'today_earnings_centavos',
          ),
          todayCompletedTrips: _readNonNegativeInt(
            values,
            'today_completed_trips',
          ),
          totalTrips: _readNonNegativeInt(values, 'total_trips'),
          completedTrips: _readNonNegativeInt(values, 'completed_trips'),
          totalEarningsCentavos: _readNonNegativeInt(
            values,
            'total_earnings_centavos',
          ),
          averageRating: _readNonNegativeDouble(values, 'average_rating'),
        ),
      );
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<Failure, OffsetPage<Map<String, dynamic>>>> fetchTripHistory(
    String driverId, {
    int limit = 25,
    int offset = 0,
    bool activeOnly = false,
  }) async {
    try {
      return Right(
        await _remoteDataSource.fetchTripHistory(
          driverId,
          limit: limit,
          offset: offset,
          activeOnly: activeOnly,
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

int _readNonNegativeInt(Map<String, dynamic> values, String key) {
  final value = SafeParse.toNullableDouble(values[key]);
  if (value == null ||
      !value.isFinite ||
      value < 0 ||
      value != value.roundToDouble()) {
    throw DataParsingException(message: 'Driver statistic $key is invalid.');
  }
  return value.toInt();
}

double _readNonNegativeDouble(Map<String, dynamic> values, String key) {
  final value = SafeParse.toNullableDouble(values[key]);
  if (value == null || !value.isFinite || value < 0) {
    throw DataParsingException(message: 'Driver statistic $key is invalid.');
  }
  return value;
}

import 'package:dio/dio.dart';
import 'package:driver/src/features/auth/domain/failures/auth_failures.dart';
import 'package:driver/src/features/performance/data/data_sources/driver_performance_remote_data_source.dart';
import 'package:driver/src/features/performance/domain/entities/driver_performance_stats.dart';
import 'package:driver/src/features/performance/domain/repositories/driver_performance_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:foundation/foundation.dart';

final class DriverPerformanceRepositoryImpl({required this._dataSource})
    implements DriverPerformanceRepository {
  this;

  final DriverPerformanceRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, DriverPerformanceStats>> fetchStats(
    String driverId,
  ) async {
    try {
      final values = await _dataSource.fetchStats(driverId);
      return Right(
        DriverPerformanceStats(
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

  Failure _mapExceptionToFailure(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == null && _isTimeout(error.type)) {
        return const ServerFailure.withStatusCode(
          'Driver performance request timed out. Please try again.',
          504,
        );
      }
      if (statusCode == null) {
        return const NetworkFailure(
          'Unable to reach driver performance services. Check your connection and try again.',
        );
      }
      return FailureMapper.fromException(
        error,
        serverMessage:
            'Driver performance is temporarily unavailable. Please try again.',
        validationMessage: 'Invalid driver performance request.',
        networkMessage: 'Unable to reach driver performance services. Check your connection and try again.',
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
          'Unable to reach driver performance services. Check your connection and try again.',
        );
      }
      return ServerFailure.withStatusCode(
        'Driver performance is temporarily unavailable. Please try again.',
        error.statusCode,
      );
    }
    if (error is DataParsingException) {
      return const ValidationFailure(
        'Driver performance data is invalid. Please try again.',
      );
    }
    if (error is CacheException) return FailureMapper.fromException(error);
    return const ServerFailure(
      'Driver performance is temporarily unavailable. Please try again.',
    );
  }

  bool _isTimeout(DioExceptionType type) => switch (type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => true,
    _ => false,
  };
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

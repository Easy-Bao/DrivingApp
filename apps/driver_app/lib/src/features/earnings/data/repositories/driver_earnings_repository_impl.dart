import 'package:dio/dio.dart';
import 'package:driver_app/src/features/auth/domain/failures/auth_failures.dart';
import 'package:driver_app/src/features/earnings/data/data_sources/driver_earnings_remote_data_source.dart';
import 'package:driver_app/src/features/earnings/domain/repositories/driver_earnings_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:foundation/foundation.dart';

final class DriverEarningsRepositoryImpl implements DriverEarningsRepository {
  DriverEarningsRepositoryImpl({
    required DriverEarningsRemoteDataSource dataSource,
  }) : _dataSource = dataSource;

  final DriverEarningsRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, Map<String, dynamic>>> fetchEarningsSummary(
    String driverId,
  ) async {
    try {
      return Right(await _dataSource.fetchEarningsSummary(driverId));
    } catch (error) {
      return Left(_mapExceptionToFailure(error));
    }
  }

  Failure _mapExceptionToFailure(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == null && _isTimeout(error.type)) {
        return const ServerFailure.withStatusCode(
          'Driver earnings request timed out. Please try again.',
          504,
        );
      }
      if (statusCode == null) {
        return const NetworkFailure(
          'Unable to reach driver earnings services. Check your connection and try again.',
        );
      }
      return FailureMapper.fromException(
        error,
        serverMessage:
            'Driver earnings are temporarily unavailable. Please try again.',
        validationMessage: 'Invalid driver earnings request.',
        networkMessage: 'Unable to reach driver earnings services. Check your connection and try again.',
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
          'Unable to reach driver earnings services. Check your connection and try again.',
        );
      }
      return ServerFailure.withStatusCode(
        'Driver earnings are temporarily unavailable. Please try again.',
        error.statusCode,
      );
    }
    if (error is CacheException) return FailureMapper.fromException(error);
    return const ServerFailure(
      'Driver earnings are temporarily unavailable. Please try again.',
    );
  }

  bool _isTimeout(DioExceptionType type) => switch (type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => true,
    _ => false,
  };
}

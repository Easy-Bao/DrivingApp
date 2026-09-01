import 'package:dio/dio.dart';
import 'package:driver/src/features/auth/domain/failures/auth_failures.dart';
import 'package:driver/src/features/ride_history/data/data_sources/driver_ride_history_remote_data_source.dart';
import 'package:driver/src/features/ride_history/domain/repositories/driver_ride_history_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:foundation/foundation.dart';

final class DriverRideHistoryRepositoryImpl({
  required DriverRideHistoryRemoteDataSource dataSource,
}) implements DriverRideHistoryRepository {
  this : _dataSource = dataSource;

  final DriverRideHistoryRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, OffsetPage<Map<String, dynamic>>>> fetchTripHistory(
    String driverId, {
    int limit = 25,
    int offset = 0,
    bool activeOnly = false,
  }) async {
    try {
      return Right(
        await _dataSource.fetchTripHistory(
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

  Failure _mapExceptionToFailure(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == null && _isTimeout(error.type)) {
        return const ServerFailure.withStatusCode(
          'Driver trip history request timed out. Please try again.',
          504,
        );
      }
      if (statusCode == null) {
        return const NetworkFailure(
          'Unable to reach driver trip history services. Check your connection and try again.',
        );
      }
      return FailureMapper.fromException(
        error,
        serverMessage:
            'Driver trip history is temporarily unavailable. Please try again.',
        validationMessage: 'Invalid driver trip history request.',
        networkMessage: 'Unable to reach driver trip history services. Check your connection and try again.',
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
          'Unable to reach driver trip history services. Check your connection and try again.',
        );
      }
      return ServerFailure.withStatusCode(
        'Driver trip history is temporarily unavailable. Please try again.',
        error.statusCode,
      );
    }
    if (error is DataParsingException) {
      return const ValidationFailure(
        'Driver trip history data is invalid. Please try again.',
      );
    }
    if (error is CacheException) return FailureMapper.fromException(error);
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
}

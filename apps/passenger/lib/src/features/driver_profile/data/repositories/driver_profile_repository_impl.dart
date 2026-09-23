import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/auth/domain/failures/auth_failures.dart';
import 'package:passenger/src/features/driver_profile/data/data_sources/driver_profile_remote_data_source.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_profile_stats.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_review.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';

final class DriverProfileRepositoryImpl({required this._dataSource})
    implements DriverProfileRepository {
  final DriverProfileRemoteDataSource _dataSource;

  @override
  Future<Result<DriverProfileStats, Failure>> fetchStats(
    String driverId,
  ) async {
    try {
      final response = await _dataSource.fetchStats(driverId);
      final nested = response['data'];
      final stats = nested is Map
          ? Map<String, dynamic>.from(nested)
          : response;
      final completedTrips = SafeParse.toNullableDouble(
        stats['completed_trips'] ??
            stats['completedTrips'] ??
            stats['total_trips'] ??
            stats['totalTrips'],
      );
      if (completedTrips == null || completedTrips < 0) {
        return const Err(
          ValidationFailure('Driver statistics are incomplete.'),
        );
      }
      return Ok(DriverProfileStats(completedTrips: completedTrips.toInt()));
    } catch (error) {
      return Err(_mapFailure(error));
    }
  }

  @override
  Future<Result<List<DriverReview>, Failure>> fetchReviews(
    String driverId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final raw = await _dataSource.fetchReviews(
        driverId,
        page: page,
        limit: limit,
      );
      return Ok(
        raw
            .map(DriverReview.fromJson)
            .where((review) => review.rating > 0 && review.rating <= 5)
            .toList(growable: false),
      );
    } catch (error) {
      return Err(_mapFailure(error));
    }
  }

  @override
  Future<Result<void, Failure>> submitReview({
    required String driverId,
    required String rideId,
    required double rating,
    required String comment,
  }) async {
    if (!rating.isFinite || rating < 1 || rating > 5) {
      return const Err(ValidationFailure('Rating must be between 1 and 5.'));
    }
    try {
      final submitted = await _dataSource.submitReview(
        driverId: driverId,
        rideId: rideId,
        rating: rating,
        comment: comment.trim(),
      );
      return submitted
          ? const Ok(null)
          : const Err(ServerFailure('The rating was not accepted.'));
    } catch (error) {
      return Err(_mapFailure(error));
    }
  }
}

Failure _mapFailure(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      return const AuthFailure(
        'Your passenger session has ended. Sign in again.',
      );
    }
    if (statusCode == 403) {
      return const ServerFailure.withStatusCode(
        'You do not have permission to access driver profiles.',
        403,
      );
    }
    if (statusCode == 400 || statusCode == 409 || statusCode == 422) {
      return const ValidationFailure('The driver review request is invalid.');
    }
    if (statusCode == null) {
      return const NetworkFailure(
        'Unable to reach driver profiles. Check your connection.',
      );
    }
    return ServerFailure.withStatusCode(
      'Driver profiles are temporarily unavailable.',
      statusCode,
    );
  }
  if (error is ServerException) {
    return FailureMapper.fromException(
      error,
      serverMessage: 'Driver profiles are temporarily unavailable.',
    );
  }
  if (error is FormatException || error is DataParsingException) {
    return const ValidationFailure('Driver profile data is invalid.');
  }
  return const ServerFailure('Driver profiles are temporarily unavailable.');
}

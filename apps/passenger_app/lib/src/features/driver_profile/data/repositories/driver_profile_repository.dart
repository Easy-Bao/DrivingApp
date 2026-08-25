import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/driver_profile/data/datasources/driver_profile_remote_data_source.dart';
import 'package:passenger_app/src/features/driver_profile/domain/entities/driver_profile_stats.dart';
import 'package:passenger_app/src/features/driver_profile/domain/entities/driver_review.dart';
import 'package:passenger_app/src/features/driver_profile/domain/repositories/i_driver_profile_repository.dart';
import 'package:shared_core/shared_core.dart';

class DriverProfileRepository implements IDriverProfileRepository {
  DriverProfileRepository({required DriverProfileRemoteDataSource dataSource})
    : _dataSource = dataSource;

  final DriverProfileRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, DriverProfileStats>> fetchStats(
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
        return const Left(
          ValidationFailure('Driver statistics are incomplete.'),
        );
      }
      return Right(DriverProfileStats(completedTrips: completedTrips.toInt()));
    } catch (error) {
      return Left(_mapFailure(error));
    }
  }

  @override
  Future<Either<Failure, List<DriverReview>>> fetchReviews(
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
      return Right(
        raw
            .whereType<Map>()
            .map(
              (value) =>
                  DriverReview.fromJson(Map<String, dynamic>.from(value)),
            )
            .where((review) => review.rating > 0 && review.rating <= 5)
            .toList(growable: false),
      );
    } catch (error) {
      return Left(_mapFailure(error));
    }
  }

  @override
  Future<Either<Failure, void>> submitReview({
    required String driverId,
    required String rideId,
    required double rating,
    required String comment,
  }) async {
    if (!rating.isFinite || rating < 1 || rating > 5) {
      return const Left(ValidationFailure('Rating must be between 1 and 5.'));
    }
    try {
      final submitted = await _dataSource.submitReview(
        driverId: driverId,
        rideId: rideId,
        rating: rating,
        comment: comment.trim(),
      );
      return submitted
          ? const Right(null)
          : const Left(ServerFailure('The rating was not accepted.'));
    } catch (error) {
      return Left(_mapFailure(error));
    }
  }
}

Failure _mapFailure(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return const AuthFailure(
        'Your passenger session has ended. Sign in again.',
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
    return ServerFailure.withStatusCode(error.message, error.statusCode);
  }
  if (error is FormatException || error is DataParsingException) {
    return const ValidationFailure('Driver profile data is invalid.');
  }
  return const ServerFailure('Driver profiles are temporarily unavailable.');
}

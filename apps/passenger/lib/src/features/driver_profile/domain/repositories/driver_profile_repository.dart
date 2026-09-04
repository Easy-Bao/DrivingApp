import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_profile_stats.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_review.dart';

abstract interface class DriverProfileRepository {
  Future<Either<Failure, DriverProfileStats>> fetchStats(String driverId);

  Future<Either<Failure, List<DriverReview>>> fetchReviews(
    String driverId, {
    int page = 1,
    int limit = 20,
  });

  Future<Either<Failure, void>> submitReview({
    required String driverId,
    required String rideId,
    required double rating,
    required String comment,
  });
}

extension DriverProfileRepositoryResultApi on DriverProfileRepository {
  Future<Result<DriverProfileStats, DomainFailure>> fetchStatsResult(
    String driverId,
  ) {
    return _captureDriverProfileResult(
      () => fetchStats(driverId),
      message: 'Driver statistics are temporarily unavailable.',
    );
  }

  Future<Result<List<DriverReview>, DomainFailure>> fetchReviewsResult(
    String driverId, {
    int page = 1,
    int limit = 20,
  }) {
    return _captureDriverProfileResult(
      () => fetchReviews(driverId, page: page, limit: limit),
      message: 'Driver reviews are temporarily unavailable.',
    );
  }

  Future<Result<void, DomainFailure>> submitReviewResult({
    required String driverId,
    required String rideId,
    required double rating,
    required String comment,
  }) {
    return _captureDriverProfileResult(
      () => submitReview(
        driverId: driverId,
        rideId: rideId,
        rating: rating,
        comment: comment,
      ),
      message: 'Unable to submit your driver review right now.',
    );
  }
}

Future<Result<T, DomainFailure>> _captureDriverProfileResult<T>(
  Future<Either<Failure, T>> Function() operation, {
  required String message,
}) async {
  try {
    final result = await operation();
    final Result<T, DomainFailure> converted = result
        .fold<Result<T, DomainFailure>>(
          (failure) => Err<T, DomainFailure>(failure),
          (value) => Ok<T, DomainFailure>(value),
        );
    return converted;
  } catch (error) {
    return Err<T, DomainFailure>(
      FailureMapper.fromException(error, serverMessage: message),
    );
  }
}

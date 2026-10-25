import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_profile_stats.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_review.dart';

abstract interface class DriverProfileRepository {
  Future<Result<DriverProfileStats, Failure>> fetchStats(String driverId);

  Future<Result<OffsetPage<DriverReview>, Failure>> fetchReviews(
    String driverId, {
    int page = 1,
    String? cursor = '',
    int limit = 20,
  });

  Future<Result<DriverReview?, Failure>> fetchMyRideReview(String rideId);

  Future<Result<void, Failure>> submitReview({
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
    return captureResult(
      () => fetchStats(driverId),
      message: 'Driver statistics are temporarily unavailable.',
    );
  }

  Future<Result<OffsetPage<DriverReview>, DomainFailure>> fetchReviewsResult(
    String driverId, {
    int page = 1,
    String? cursor = '',
    int limit = 20,
  }) {
    return captureResult(
      () => fetchReviews(driverId, page: page, limit: limit, cursor: cursor),
      message: 'Driver reviews are temporarily unavailable.',
    );
  }

  Future<Result<DriverReview?, DomainFailure>> fetchMyRideReviewResult(
    String rideId,
  ) {
    return captureResult(
      () => fetchMyRideReview(rideId),
      message: 'Your ride rating is temporarily unavailable.',
    );
  }

  Future<Result<void, DomainFailure>> submitReviewResult({
    required String driverId,
    required String rideId,
    required double rating,
    required String comment,
  }) {
    return captureResult(
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

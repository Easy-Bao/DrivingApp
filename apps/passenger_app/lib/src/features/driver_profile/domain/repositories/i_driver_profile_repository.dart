import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/driver_profile/domain/entities/driver_profile_stats.dart';
import 'package:passenger_app/src/features/driver_profile/domain/entities/driver_review.dart';
import 'package:foundation/foundation.dart';

abstract class IDriverProfileRepository {
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

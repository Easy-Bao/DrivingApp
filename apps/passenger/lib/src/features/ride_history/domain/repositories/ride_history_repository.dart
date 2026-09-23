import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/ride_history/domain/entities/ride_history_overview.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';

abstract interface class RideHistoryRepository {
  Future<Result<RideHistoryOverview, Failure>> fetchRideHistoryOverview(
    String passengerId, {
    int limit = 25,
  });

  Future<Result<OffsetPage<RideHistory>, Failure>> fetchRideHistory(
    String passengerId, {
    int limit = 25,
    int offset = 0,
  });
}

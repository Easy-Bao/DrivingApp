import 'package:passenger_app/src/features/ride_history/ride_history.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/ride_history/domain/entities/ride_history_overview.dart';
import 'package:foundation/foundation.dart';

abstract interface class RideHistoryRepository {
  Future<Either<Failure, RideHistoryOverview>> fetchRideHistoryOverview(
    String passengerId, {
    int limit = 25,
  });

  Future<Either<Failure, OffsetPage<RideHistory>>> fetchRideHistory(
    String passengerId, {
    int limit = 25,
    int offset = 0,
  });
}

import 'package:passenger_app/src/features/activity/activity.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/activity/domain/entities/activity_overview.dart';
import 'package:foundation/foundation.dart';

abstract interface class ActivityRepository {
  Future<Either<Failure, ActivityOverview>> fetchActivityOverview(
    String passengerId, {
    int limit = 25,
  });

  Future<Either<Failure, OffsetPage<RideHistory>>> fetchRideHistory(
    String passengerId, {
    int limit = 25,
    int offset = 0,
  });
}

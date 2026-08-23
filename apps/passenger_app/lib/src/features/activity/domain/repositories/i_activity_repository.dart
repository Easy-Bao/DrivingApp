import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/activity/domain/entities/activity_overview.dart';
import 'package:shared_core/shared_core.dart';

abstract class IActivityRepository {
  Future<Either<Failure, ActivityOverview>> fetchActivityOverview(
    String passengerId, {
    int limit = 25,
  });

  Future<Either<Failure, OffsetPage<RideHistoryModel>>> fetchRideHistory(
    String passengerId, {
    int limit = 25,
    int offset = 0,
  });
}

import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';

/// Domain-level contract defining operations for retrieving passenger ride histories.
/// Decouples presentation controllers from raw database clients.
abstract class ActivityRepository {
  /// Fetches all past and active ride records associated with the [passengerId].
  ///
  /// Returns [Right] with a typed list of [RideHistoryModel] or [Left] with a
  /// [Failure] on network, parse, or auth errors.
  Future<Either<Failure, List<RideHistoryModel>>> fetchRideHistory(
    String passengerId,
  );
}

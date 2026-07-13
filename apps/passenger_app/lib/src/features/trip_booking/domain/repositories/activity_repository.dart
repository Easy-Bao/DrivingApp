import 'package:core_models/core_models.dart';

/// Domain-level contract defining operations for retrieving passenger ride histories.
/// Decouples presentation controllers from raw database clients.
abstract class ActivityRepository {
  /// Fetches all past and active ride records associated with the [passengerId].
  ///
  /// Throws a [Failure] on failure.
  Future<List<RideHistoryModel>> fetchRideHistory(String passengerId);
}

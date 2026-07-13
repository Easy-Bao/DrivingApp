import 'package:core_models/core_models.dart';

/// Domain-level contract defining operations for retrieving passenger ride histories.
/// Decouples presentation controllers from raw database clients.
abstract class ActivityRepository {
  /// Fetches all past and active ride records associated with the [passengerId].
  /// Throws an [ActivityRepositoryException] on failure.
  Future<List<RideHistoryModel>> fetchRideHistory(String passengerId);
}

/// Specialized exception indicating a failure occurred in the activity retrieval pipeline.
class ActivityRepositoryException implements Exception {
  final String message;
  const ActivityRepositoryException(this.message);

  @override
  String toString() => 'ActivityRepositoryException: $message';
}

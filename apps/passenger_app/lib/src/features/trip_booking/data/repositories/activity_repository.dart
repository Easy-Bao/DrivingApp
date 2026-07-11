import 'package:core_models/core_models.dart';

abstract class ActivityRepository {
  Future<List<RideHistoryModel>> fetchRideHistory(String passengerId);
}

class ActivityRepositoryException implements Exception {
  final String message;
  const ActivityRepositoryException(this.message);

  @override
  String toString() => 'ActivityRepositoryException: $message';
}

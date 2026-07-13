/// Abstract contract defining operations for retrieving driver trip histories.
abstract class DriverActivityRepository {
  /// Fetches all past and active trip history records associated with [driverId].
  Future<List<dynamic>> fetchTripHistory(String driverId);
}

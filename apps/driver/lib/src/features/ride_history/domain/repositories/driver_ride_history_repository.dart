import 'package:foundation/foundation.dart';

abstract interface class DriverRideHistoryRepository {
  Future<Result<OffsetPage<Map<String, dynamic>>, Failure>> fetchTripHistory(
    String driverId, {
    int limit = 25,
    int offset = 0,
    bool activeOnly = false,
  });
}

import 'package:foundation/foundation.dart';

abstract interface class RideHistoryRepository {
  Future<Result<OffsetPage<Map<String, dynamic>>, Failure>> fetchTripHistory(
    String driverId, {
    int limit = 25,
    int offset = 0,
    String? cursor,
    bool activeOnly = false,
  });
}

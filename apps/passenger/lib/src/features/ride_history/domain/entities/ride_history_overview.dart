import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';

class const RideHistoryOverview({
  required this.rides,
  required this.weeklyFareAmount,
  required this.weeklyRideCount,
}) {
  final OffsetPage<RideHistory> rides;
  final int weeklyFareAmount;
  final int weeklyRideCount;
}

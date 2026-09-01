import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';

class const RideHistoryOverview({
  required this.rides,
  required this.weeklyFareCentavos,
  required this.weeklyRideCount,
}) {
  final OffsetPage<RideHistory> rides;
  final int weeklyFareCentavos;
  final int weeklyRideCount;
}

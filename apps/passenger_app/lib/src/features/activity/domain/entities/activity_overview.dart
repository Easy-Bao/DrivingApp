import 'package:passenger_app/src/features/activity/activity.dart';
import 'package:shared_core/shared_core.dart';

class ActivityOverview {
  final OffsetPage<RideHistory> rides;
  final int weeklyFareCentavos;
  final int weeklyRideCount;

  const ActivityOverview({
    required this.rides,
    required this.weeklyFareCentavos,
    required this.weeklyRideCount,
  });
}

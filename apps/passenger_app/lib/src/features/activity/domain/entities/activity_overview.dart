import 'package:shared_core/shared_core.dart';

class ActivityOverview {
  final OffsetPage<RideHistoryModel> rides;
  final int weeklyFareCentavos;
  final int weeklyRideCount;

  const ActivityOverview({
    required this.rides,
    required this.weeklyFareCentavos,
    required this.weeklyRideCount,
  });
}

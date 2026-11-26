import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

enum DriverTripHistoryFilter { all, completed, cancelled }

class const TripHistoryFilterBar({
  super.key,
  required this.selectedFilter,
  required this.onSelected,
}) extends StatelessWidget {
  final DriverTripHistoryFilter selectedFilter;
  final ValueChanged<DriverTripHistoryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return AppSegmentedTabBar<DriverTripHistoryFilter>(
      selectedValue: selectedFilter,
      onSelected: onSelected,
      indicatorKey: 'driver-trips-filter-indicator',
      itemKeyPrefix: 'driver-trips-filter',
      options: const [
        AppSegmentedTabOption(
          value: DriverTripHistoryFilter.all,
          label: 'All',
          keySuffix: 'all',
        ),
        AppSegmentedTabOption(
          value: DriverTripHistoryFilter.completed,
          label: 'Completed',
          keySuffix: 'completed',
        ),
        AppSegmentedTabOption(
          value: DriverTripHistoryFilter.cancelled,
          label: 'Canceled',
          keySuffix: 'cancelled',
        ),
      ],
    );
  }
}

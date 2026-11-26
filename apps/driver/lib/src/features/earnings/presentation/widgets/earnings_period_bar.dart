import 'package:design_system/design_system.dart';
import 'package:driver/src/features/earnings/domain/entities/earnings_summary.dart';
import 'package:material_ui/material_ui.dart';

class const EarningsPeriodBar({
  super.key,
  required this.selectedPeriod,
  required this.onSelected,
}) extends StatelessWidget {
  final EarningsPeriod selectedPeriod;
  final ValueChanged<EarningsPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    return AppSegmentedTabBar<EarningsPeriod>(
      selectedValue: selectedPeriod,
      onSelected: onSelected,
      indicatorKey: 'driver-earnings-period-indicator',
      itemKeyPrefix: 'driver-earnings-period',
      options: const [
        AppSegmentedTabOption(
          value: EarningsPeriod.daily,
          label: 'Day',
          keySuffix: 'daily',
        ),
        AppSegmentedTabOption(
          value: EarningsPeriod.weekly,
          label: 'Week',
          keySuffix: 'weekly',
        ),
        AppSegmentedTabOption(
          value: EarningsPeriod.monthly,
          label: 'Month',
          keySuffix: 'monthly',
        ),
      ],
    );
  }
}

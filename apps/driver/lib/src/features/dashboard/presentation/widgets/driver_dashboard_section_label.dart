import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class DriverDashboardSectionLabel extends StatelessWidget {
  const DriverDashboardSectionLabel({
    this.label,
    this.activeRideCount,
    super.key,
  });

  const DriverDashboardSectionLabel.activeRides({
    required int activeRideCount,
    Key? key,
  }) : this(activeRideCount: activeRideCount, key: key);

  static const maximumActiveRides = 5;

  final String? label;
  final int? activeRideCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Text(
        label ??
            'Your active rides (${activeRideCount ?? 0}/$maximumActiveRides)',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: context.colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

typedef DriverDashboardSectionLabelWidget = DriverDashboardSectionLabel;

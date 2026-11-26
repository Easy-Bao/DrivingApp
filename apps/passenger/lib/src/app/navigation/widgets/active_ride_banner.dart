import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/app/navigation/widgets/shell_status_banner.dart';

class const ActiveRideBanner({
  required this.statusText,
  required this.driverName,
  required this.vehicleInfo,
  required this.onResume,
  super.key,
}) extends StatelessWidget {
  final String statusText;
  final String driverName;
  final String vehicleInfo;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final vehicleSummary = vehicleInfo.isEmpty ? '' : ' • $vehicleInfo';

    return ShellStatusBanner(
      inkWellKey: const Key('active-ride-banner'),
      title: statusText,
      subtitle: '$driverName$vehicleSummary',
      icon: LucideIcons.car,
      badgeBorderColor: colors.outlineVariant,
      iconColor: colors.onSurface,
      statusDotColor: context.semanticColors.success,
      actionLabel: 'Resume Trip',
      showActionArrow: true,
      onAction: onResume,
    );
  }
}

import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/app/navigation/widgets/shell_status_banner.dart';

class const PendingBookingBanner({
  super.key,
  required this.isAuthenticated,
  required this.destinationName,
  required this.onContinue,
  required this.onDismiss,
}) extends StatelessWidget {
  final bool isAuthenticated;
  final String destinationName;
  final VoidCallback onContinue;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    if (!isAuthenticated) return const SizedBox.shrink();

    final colors = context.colorScheme;
    return ShellStatusBanner(
      inkWellKey: const Key('pending-booking-banner'),
      title: 'Continue your booking',
      subtitle: destinationName,
      icon: LucideIcons.route,
      badgeBorderColor: colors.outlineVariant,
      iconColor: colors.onSurface,
      actionLabel: 'Continue',
      onAction: onContinue,
      onDismiss: onDismiss,
      dismissKey: const Key('pending-booking-banner-dismiss'),
      dismissTooltip: 'Dismiss booking draft',
    );
  }
}

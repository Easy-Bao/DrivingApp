import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/app/navigation/widgets/shell_status_banner.dart';

enum ActiveBookingBannerTone { active, matched, warning, error }

class const ActiveBookingBanner({
  required this.title,
  required this.subtitle,
  required this.tone,
  this.isLoading = false,
  this.icon = LucideIcons.clock,
  this.actionLabel,
  this.showActionArrow = false,
  this.onAction,
  this.onDismiss,
  this.announceLiveRegion = false,
  super.key,
}) extends StatelessWidget {
  final String title;
  final String subtitle;
  final ActiveBookingBannerTone tone;
  final bool isLoading;
  final IconData icon;
  final String? actionLabel;
  final bool showActionArrow;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final bool announceLiveRegion;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final semantic = context.semanticColors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final Color indicatorColor = switch (tone) {
      ActiveBookingBannerTone.active => colors.primary,
      ActiveBookingBannerTone.matched => semantic.success,
      ActiveBookingBannerTone.warning => semantic.warning,
      ActiveBookingBannerTone.error => colors.error,
    };

    final Color badgeBorderColor = switch (tone) {
      ActiveBookingBannerTone.active ||
      ActiveBookingBannerTone.matched => colors.outlineVariant,
      ActiveBookingBannerTone.warning => semantic.warning.withValues(
        alpha: 0.45,
      ),
      ActiveBookingBannerTone.error => colors.error.withValues(alpha: 0.45),
    };

    final Color iconColor = switch (tone) {
      ActiveBookingBannerTone.active ||
      ActiveBookingBannerTone.matched => colors.onSurface,
      ActiveBookingBannerTone.warning => semantic.warning,
      ActiveBookingBannerTone.error => colors.error,
    };

    return ShellStatusBanner(
      inkWellKey: const Key('active-booking-banner'),
      title: title,
      subtitle: subtitle,
      icon: icon,
      badgeBorderColor: badgeBorderColor,
      iconColor: iconColor,
      statusDotColor: indicatorColor,
      showSpinner: isLoading && !reduceMotion,
      actionLabel: actionLabel,
      showActionArrow: showActionArrow,
      onAction: onAction,
      onDismiss: onDismiss,
      dismissKey: const Key('active-booking-banner-dismiss'),
      dismissTooltip: 'Dismiss booking notice',
      announceLiveRegion: announceLiveRegion,
    );
  }
}

import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

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

    final content = Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: const Key('active-booking-banner'),
        enableFeedback: false,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? colors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        onTap: onAction,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              _BookingStatusBadge(
                borderColor: badgeBorderColor,
                iconColor: iconColor,
                icon: icon,
                showSpinner: isLoading && !reduceMotion,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: indicatorColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            title,
                            style: context.textStyles.titleSmall?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: AppSpacing.sm),
                _BookingBannerActionButton(
                  label: actionLabel!,
                  showArrow: showActionArrow,
                  onPressed: onAction!,
                ),
              ],
              if (onDismiss != null) ...[
                const SizedBox(width: 4),
                _DismissBannerButton(onDismiss: onDismiss!),
              ],
            ],
          ),
        ),
      ),
    );

    if (!announceLiveRegion) return content;
    return Semantics(liveRegion: true, child: content);
  }
}

class const _BookingStatusBadge({
  required this.borderColor,
  required this.iconColor,
  required this.icon,
  required this.showSpinner,
}) extends StatelessWidget {
  final Color borderColor;
  final Color iconColor;
  final IconData icon;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
      ),
      alignment: Alignment.center,
      child: showSpinner
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.onSurface,
              ),
            )
          : Icon(icon, color: iconColor, size: 17),
    );
  }
}

class const _BookingBannerActionButton({
  required this.label,
  required this.showArrow,
  required this.onPressed,
}) extends StatelessWidget {
  final String label;
  final bool showArrow;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final style =
        FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          enableFeedback: false,
          splashFactory: NoSplash.splashFactory,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 8,
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: context.textStyles.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? colors.onPrimary.withValues(alpha: 0.16)
                : Colors.transparent,
          ),
        );

    if (showArrow) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(LucideIcons.arrow_right, size: 14),
        label: Text(label),
        style: style,
      );
    }

    return FilledButton(onPressed: onPressed, style: style, child: Text(label));
  }
}

class const _DismissBannerButton({required this.onDismiss})
    extends StatelessWidget {
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return IconButton(
      key: const Key('active-booking-banner-dismiss'),
      tooltip: 'Dismiss booking notice',
      onPressed: onDismiss,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      style:
          IconButton.styleFrom(
            foregroundColor: colors.onSurfaceVariant,
            enableFeedback: false,
            splashFactory: NoSplash.splashFactory,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? colors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
            ),
          ),
      icon: const Icon(LucideIcons.x, size: 16),
    );
  }
}

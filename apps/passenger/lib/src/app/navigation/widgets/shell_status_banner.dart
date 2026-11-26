import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class ShellStatusBanner extends StatelessWidget {
  const ShellStatusBanner({
    super.key,
    required this.inkWellKey,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badgeBorderColor,
    required this.iconColor,
    this.statusDotColor,
    this.showSpinner = false,
    this.actionLabel,
    this.showActionArrow = false,
    this.onAction,
    this.onDismiss,
    this.dismissKey,
    this.dismissTooltip,
    this.announceLiveRegion = false,
    this.dismissSpacing = AppSpacing.xs,
  });

  final Key inkWellKey;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color badgeBorderColor;
  final Color iconColor;
  final Color? statusDotColor;
  final bool showSpinner;
  final String? actionLabel;
  final bool showActionArrow;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final Key? dismissKey;
  final String? dismissTooltip;
  final bool announceLiveRegion;
  final double dismissSpacing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final actionText = actionLabel;
    final actionCallback = onAction;
    final dismissCallback = onDismiss;
    final dotColor = statusDotColor;

    final content = Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: inkWellKey,
        enableFeedback: false,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? colors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        onTap: actionCallback,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              _ShellBannerBadge(
                borderColor: badgeBorderColor,
                iconColor: iconColor,
                icon: icon,
                showSpinner: showSpinner,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dotColor != null)
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(child: _buildTitle(context, colors)),
                        ],
                      )
                    else
                      _buildTitle(context, colors),
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
              if (actionText != null && actionCallback != null) ...[
                const SizedBox(width: AppSpacing.sm),
                _ShellBannerActionButton(
                  label: actionText,
                  showArrow: showActionArrow,
                  onPressed: actionCallback,
                ),
              ],
              if (dismissCallback != null) ...[
                SizedBox(width: dismissSpacing),
                _ShellBannerDismissButton(
                  buttonKey: dismissKey,
                  tooltip: dismissTooltip,
                  onDismiss: dismissCallback,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!announceLiveRegion) return content;
    return Semantics(liveRegion: true, child: content);
  }

  Widget _buildTitle(BuildContext context, ColorScheme colors) {
    return Text(
      title,
      style: context.textStyles.titleSmall?.copyWith(
        color: colors.onSurface,
        fontWeight: FontWeight.w600,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ShellBannerBadge extends StatelessWidget {
  const _ShellBannerBadge({
    required this.borderColor,
    required this.iconColor,
    required this.icon,
    required this.showSpinner,
  });

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

class _ShellBannerActionButton extends StatelessWidget {
  const _ShellBannerActionButton({
    required this.label,
    required this.showArrow,
    required this.onPressed,
  });

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
            vertical: AppSpacing.sm,
          ),
          minimumSize: const Size(AppSize.minimumTouchTarget, 36),
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

class _ShellBannerDismissButton extends StatelessWidget {
  const _ShellBannerDismissButton({
    required this.buttonKey,
    required this.tooltip,
    required this.onDismiss,
  });

  final Key? buttonKey;
  final String? tooltip;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return IconButton(
      key: buttonKey,
      tooltip: tooltip,
      onPressed: onDismiss,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: AppSize.minimumTouchTarget,
        minHeight: AppSize.minimumTouchTarget,
      ),
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

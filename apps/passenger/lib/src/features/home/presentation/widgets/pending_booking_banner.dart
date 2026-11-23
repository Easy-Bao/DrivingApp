import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              shape: BoxShape.circle,
              border: Border.all(color: colors.outlineVariant),
            ),
            alignment: Alignment.center,
            child: Icon(LucideIcons.route, size: 17, color: colors.onSurface),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue your booking',
                  style: context.textStyles.titleSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  destinationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: onContinue,
            style:
                FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  elevation: 0,
                  enableFeedback: false,
                  splashFactory: NoSplash.splashFactory,
                  minimumSize: const Size(48, AppSize.minimumTouchTarget),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  textStyle: context.textStyles.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.focused)
                        ? colors.onPrimary.withValues(alpha: 0.16)
                        : Colors.transparent,
                  ),
                ),
            child: const Text('Continue'),
          ),
          IconButton(
            tooltip: 'Dismiss booking draft',
            onPressed: onDismiss,
            style:
                IconButton.styleFrom(
                  foregroundColor: colors.onSurfaceVariant,
                  enableFeedback: false,
                  splashFactory: NoSplash.splashFactory,
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.focused)
                        ? colors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                  ),
                ),
            constraints: const BoxConstraints(
              minWidth: AppSize.minimumTouchTarget,
              minHeight: AppSize.minimumTouchTarget,
            ),
            icon: const Icon(LucideIcons.x, size: 17),
          ),
        ],
      ),
    );
  }
}

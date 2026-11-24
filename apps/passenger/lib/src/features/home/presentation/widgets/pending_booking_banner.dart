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
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: const Key('pending-booking-banner'),
        enableFeedback: false,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? colors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        onTap: onContinue,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.outlineVariant),
                ),
                alignment: Alignment.center,
                child: Icon(
                  LucideIcons.route,
                  size: 17,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Continue your booking',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      textStyle: context.textStyles.labelSmall?.copyWith(
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
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                key: const Key('pending-booking-banner-dismiss'),
                tooltip: 'Dismiss booking draft',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

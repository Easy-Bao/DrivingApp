import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

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

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: const Key('active-ride-banner'),
        enableFeedback: false,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? colors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        onTap: onResume,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              _VehicleAvatarBadge(colorScheme: colors),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _StatusIndicatorDot(
                          color: context.semanticColors.success,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            statusText,
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
                      '$driverName$vehicleSummary',
                      style: context.textStyles.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ResumeTripButton(onResume: onResume),
            ],
          ),
        ),
      ),
    );
  }
}

class const _VehicleAvatarBadge({required this.colorScheme})
    extends StatelessWidget {
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      alignment: Alignment.center,
      child: Icon(LucideIcons.car, color: colorScheme.onSurface, size: 17),
    );
  }
}

class const _StatusIndicatorDot({required this.color}) extends StatelessWidget {
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class const _ResumeTripButton({required this.onResume})
    extends StatelessWidget {
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return FilledButton.icon(
      onPressed: onResume,
      icon: const Icon(LucideIcons.arrow_right, size: 14),
      label: const Text('Resume Trip'),
      style:
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
          ),
    );
  }
}

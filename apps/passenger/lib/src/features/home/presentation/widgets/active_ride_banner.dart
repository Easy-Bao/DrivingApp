import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

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
        onTap: onResume,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              _VehicleAvatarBadge(colorScheme: colors),
              const SizedBox(width: 10),
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
                            style: context.textStyles.labelMedium?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w700,
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
                      style: context.textStyles.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
        color: colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(LucideIcons.car, color: colorScheme.primary, size: 18),
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
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
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
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: context.textStyles.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}

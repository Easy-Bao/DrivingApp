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
    final vehicleSummary = vehicleInfo.isEmpty ? '' : ' • $vehicleInfo';
    final radius = BorderRadius.circular(EasyRideRadius.lg);
    final colors = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 440;
          final details = _buildRideDetails(context, vehicleSummary);
          final resumeButton = FilledButton.icon(
            onPressed: onResume,
            icon: const Icon(LucideIcons.arrow_right, size: 18),
            label: const Text('Resume Trip'),
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: EasyRideSpacing.md,
              ),
              minimumSize: const Size(0, EasyRideSize.minimumTouchTarget),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(EasyRideRadius.pill),
              ),
            ),
          );

          return Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: InkWell(
              key: const Key('active-ride-banner'),
              borderRadius: radius,
              excludeFromSemantics: true,
              onTap: onResume,
              child: Padding(
                padding: const EdgeInsets.all(EasyRideSpacing.md),
                child: isCompact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildVehicleIcon(context),
                              const SizedBox(width: EasyRideSpacing.md),
                              Expanded(child: details),
                            ],
                          ),
                          const SizedBox(height: EasyRideSpacing.md),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: resumeButton,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          _buildVehicleIcon(context),
                          const SizedBox(width: EasyRideSpacing.md),
                          Expanded(child: details),
                          const SizedBox(width: EasyRideSpacing.md),
                          resumeButton,
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVehicleIcon(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        LucideIcons.car,
        color: context.colorScheme.primary,
        size: 20,
      ),
    );
  }

  Widget _buildRideDetails(BuildContext context, String vehicleSummary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: context.semanticColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: EasyRideSpacing.xs),
            Expanded(
              child: Text(
                statusText,
                style: context.textStyles.labelMedium?.copyWith(
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: EasyRideSpacing.xs),
        Text(
          '$driverName$vehicleSummary',
          style: context.textStyles.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

typedef ActiveRideBannerWidget = ActiveRideBanner;

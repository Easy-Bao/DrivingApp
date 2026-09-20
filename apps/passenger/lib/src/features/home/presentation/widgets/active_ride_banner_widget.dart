import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class const ActiveRideBannerWidget({
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: context.colorScheme.primary,
        borderRadius: radius,
        elevation: 2,
        child: InkWell(
          key: const Key('active-ride-banner'),
          borderRadius: radius,
          onTap: onResume,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EasyRideSpacing.md,
              vertical: EasyRideSpacing.sm + 2,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.colorScheme.onPrimary.withValues(
                      alpha: 0.15,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.car,
                    color: context.colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
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
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              statusText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.labelMedium?.copyWith(
                                color: context.colorScheme.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$driverName$vehicleSummary',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colorScheme.onPrimary.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onResume,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colorScheme.onPrimary,
                    foregroundColor: context.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, EasyRideSize.minimumTouchTarget),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(EasyRideRadius.pill),
                    ),
                  ),
                  child: const Text('Resume Trip'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

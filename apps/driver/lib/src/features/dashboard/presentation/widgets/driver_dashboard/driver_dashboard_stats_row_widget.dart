import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:foundation/foundation.dart';
import 'package:design_system/design_system.dart';

class const DriverDashboardStatsRowWidget({
  super.key,
  required this.isLoadingStats,
  required this.earnings,
  required this.completedTrips,
  this.hasExistingStats = false,
}) extends StatelessWidget {
  final bool isLoadingStats;
  final double earnings;
  final int completedTrips;
  final bool hasExistingStats;

  @override
  Widget build(BuildContext context) {
    if (isLoadingStats && !hasExistingStats) {
      return _buildInitialLoadingState(context);
    }

    return Skeletonizer.zone(
      key: const ValueKey<String>('driver-dashboard-stats-skeleton'),
      enabled: isLoadingStats && hasExistingStats,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: EasyRideLayout.pagePadding,
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                label: "Today's Net Earnings",
                value: formatPesoAmount(earnings),
                skeletonWidth: 84,
                icon: LucideIcons.wallet,
              ),
            ),
            const SizedBox(width: EasyRideSpacing.sm),
            Expanded(
              child: _buildStatCard(
                context,
                label: 'Trips Today',
                value: '$completedTrips',
                skeletonWidth: 32,
                icon: LucideIcons.car,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required double skeletonWidth,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(EasyRideSpacing.lg),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.labelSmall?.copyWith(
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: EasyRideSpacing.xs),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isLoadingStats && hasExistingStats)
            Bone.text(width: skeletonWidth, fontSize: 24)
          else
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: context.colorScheme.onSurface,
                letterSpacing: -0.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInitialLoadingState(BuildContext context) {
    return Skeletonizer.zone(
      key: const ValueKey<String>('driver-dashboard-stats-loading'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: EasyRideLayout.pagePadding,
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildInitialSkeletonCard(
                context,
                labelWidth: 94,
                valueWidth: 76,
                icon: LucideIcons.wallet,
              ),
            ),
            const SizedBox(width: EasyRideSpacing.sm),
            Expanded(
              child: _buildInitialSkeletonCard(
                context,
                labelWidth: 64,
                valueWidth: 32,
                icon: LucideIcons.car,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialSkeletonCard(
    BuildContext context, {
    required double labelWidth,
    required double valueWidth,
    required IconData icon,
  }) {
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(EasyRideSpacing.lg),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(EasyRideRadius.lg),
          border: Border.all(color: context.colorScheme.outlineVariant),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Bone.text(width: labelWidth, fontSize: 11)),
              Bone.icon(size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Bone.text(width: valueWidth, fontSize: 24),
        ],
      ),
    );
  }
}

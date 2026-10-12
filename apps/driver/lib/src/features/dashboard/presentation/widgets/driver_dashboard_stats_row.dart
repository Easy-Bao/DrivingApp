import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:foundation/foundation.dart';
import 'package:design_system/design_system.dart';

class DriverDashboardStatsRow extends StatelessWidget {
  const DriverDashboardStatsRow({
    super.key,
    required this.isLoadingStats,
    required this.earnings,
    required this.completedTrips,
    this.hasExistingStats = false,
    this.hasError = false,
    this.onRetry,
  });

  final bool isLoadingStats;
  final double earnings;
  final int completedTrips;
  final bool hasExistingStats;
  final bool hasError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoadingStats && !hasExistingStats) {
      return _buildInitialLoadingState(context);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EasyRideLayout.pagePadding,
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  label: "Today's Net Earnings",
                  value: hasError && !hasExistingStats
                      ? '—'
                      : formatPesoAmount(earnings),
                  icon: LucideIcons.wallet,
                ),
              ),
              const SizedBox(width: EasyRideSpacing.sm),
              Expanded(
                child: _buildStatCard(
                  context,
                  label: 'Trips Today',
                  value: hasError && !hasExistingStats
                      ? '—'
                      : '$completedTrips',
                  icon: LucideIcons.car,
                ),
              ),
            ],
          ),
        ),
        if (hasError) _buildErrorState(context),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: EasyRideLayout.pagePadding,
        right: EasyRideLayout.pagePadding,
        top: EasyRideSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.circle_alert,
            size: 16,
            color: context.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: EasyRideSpacing.xs),
          Expanded(
            child: Text(
              hasExistingStats
                  ? 'Showing last loaded stats.'
                  : "Today's stats are unavailable.",
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton.icon(
            key: const ValueKey<String>('driver-dashboard-stats-retry'),
            onPressed: onRetry,
            icon: const Icon(LucideIcons.refresh_cw, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
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
                  maxLines: 2,
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

typedef DriverDashboardStatsRowWidget = DriverDashboardStatsRow;

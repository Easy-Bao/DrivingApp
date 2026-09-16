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
  this.errorMessage,
  this.onRetry,
}) extends StatelessWidget {
  final bool isLoadingStats;
  final double earnings;
  final int completedTrips;
  final bool hasExistingStats;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final errorMessage = this.errorMessage;
    if (errorMessage != null && !isLoadingStats) {
      return DriverDashboardErrorCard(message: errorMessage, onRetry: onRetry);
    }

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
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInitialLoadingState(BuildContext context) {
    return Padding(
      key: const ValueKey<String>('driver-dashboard-stats-loading'),
      padding: const EdgeInsets.symmetric(
        horizontal: EasyRideLayout.pagePadding,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(EasyRideSpacing.lg),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(EasyRideRadius.lg),
          border: Border.all(color: context.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Loading today's activity",
                    style: context.textStyles.labelMedium?.copyWith(
                      color: context.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your earnings and trips will appear here shortly.',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class const DriverDashboardErrorCard({
  super.key,
  required this.message,
  this.onRetry,
}) extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.colorScheme.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.colorScheme.error.withValues(alpha: 0.24),
          ),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.circle_alert,
              size: 20,
              color: context.colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.error,
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}

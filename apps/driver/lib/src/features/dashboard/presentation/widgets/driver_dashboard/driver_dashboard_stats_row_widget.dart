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
          horizontal: AppDesignTokens.pageHorizontalPadding,
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                label: "Today's Net Earnings",
                value: formatPesoAmount(earnings),
                skeletonWidth: 84,
              ),
            ),
            const SizedBox(width: AppDesignTokens.compactGap),
            Expanded(
              child: _buildStatCard(
                context,
                label: 'Trips Today',
                value: '$completedTrips',
                skeletonWidth: 32,
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
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDesignTokens.cardPadding),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDesignTokens.cardRadius),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          if (isLoadingStats && hasExistingStats)
            Bone.text(width: skeletonWidth, fontSize: 22)
          else
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: context.colorScheme.onSurface,
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
        horizontal: AppDesignTokens.pageHorizontalPadding,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.cardPadding,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppDesignTokens.cardRadius),
          border: Border.all(color: context.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: context.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Loading today's activity",
                    style: TextStyle(
                      color: context.colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your earnings and trips will appear here shortly.',
                    style: TextStyle(
                      color: context.colorScheme.onSurfaceVariant,
                      fontSize: 12,
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

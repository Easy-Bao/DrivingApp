import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:shared_core/shared_core.dart';

class DriverDashboardStatsRowWidget extends StatelessWidget {
  final bool isLoadingStats;
  final double earnings;
  final int completedTrips;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const DriverDashboardStatsRowWidget({
    super.key,
    required this.isLoadingStats,
    required this.earnings,
    required this.completedTrips,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final errorMessage = this.errorMessage;
    if (errorMessage != null && !isLoadingStats) {
      return DriverDashboardErrorCard(message: errorMessage, onRetry: onRetry);
    }

    return Skeletonizer.zone(
      enabled: isLoadingStats,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: "Today's Net Earnings",
                value: formatPesoAmount(earnings),
                skeletonWidth: 84,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
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

  Widget _buildStatCard({
    required String label,
    required String value,
    required double skeletonWidth,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          if (isLoadingStats)
            Bone.text(width: skeletonWidth, fontSize: 22)
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
              ),
            ),
        ],
      ),
    );
  }
}

class DriverDashboardErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const DriverDashboardErrorCard({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4F4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFC5C5)),
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.circle_alert,
              size: 20,
              color: Color(0xFFD92D3A),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8F1D29),
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

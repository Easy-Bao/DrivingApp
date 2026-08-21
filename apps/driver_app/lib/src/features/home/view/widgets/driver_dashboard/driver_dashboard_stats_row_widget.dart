import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DriverDashboardStatsRowWidget extends StatelessWidget {
  final bool isLoadingStats;
  final double earnings;
  final int completedTrips;

  const DriverDashboardStatsRowWidget({
    super.key,
    required this.isLoadingStats,
    required this.earnings,
    required this.completedTrips,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.zone(
      enabled: isLoadingStats,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: "Today's Earnings",
                value: '₱${earnings.toStringAsFixed(0)}',
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

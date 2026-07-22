import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_ui/shared_ui.dart';

class DriverDashboardStatsRowWidget extends StatelessWidget {
  final bool isLoadingStats;
  final double todayEarnings;
  final int todayTrips;
  final double hoursOnline;

  const DriverDashboardStatsRowWidget({
    super.key,
    required this.isLoadingStats,
    required this.todayEarnings,
    required this.todayTrips,
    required this.hoursOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
          ),
        ),
        child: isLoadingStats
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                    ),
                  ),
                ),
              )
            : Row(
                children: [
                  _StatCell(
                    value: '₱${todayEarnings.toStringAsFixed(0)}',
                    label: 'Earnings',
                    iconText: '₱',
                  ),
                  const _Divider(),
                  _StatCell(
                    value: '$todayTrips',
                    label: 'Trips',
                    icon: LucideIcons.route,
                  ),
                  const _Divider(),
                  _StatCell(
                    value: '${hoursOnline.toStringAsFixed(1)}h',
                    label: 'Online',
                    icon: LucideIcons.clock,
                  ),
                ],
              ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final String? iconText;

  const _StatCell({
    required this.value,
    required this.label,
    this.icon,
    this.iconText,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: AppTheme.primaryColor.withValues(alpha: 0.6)),
                const SizedBox(width: 4),
              ] else if (iconText != null) ...[
                Text(
                  iconText!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 2),
              ],
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: AppTheme.primaryColor.withValues(alpha: 0.12),
    );
  }
}

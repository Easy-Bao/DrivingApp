import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

class DriverDashboardTopBarWidget extends StatelessWidget {
  final String greetingText;
  final bool isOnline;
  final bool isLoadingHeatmap;

  const DriverDashboardTopBarWidget({
    super.key,
    required this.greetingText,
    required this.isOnline,
    required this.isLoadingHeatmap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good $greetingText',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryColor.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Driver',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          _StatusPill(
            isOnline: isOnline,
            isLoading: isLoadingHeatmap,
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isOnline;
  final bool isLoading;

  const _StatusPill({required this.isOnline, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isOnline
            ? AppTheme.complete.withValues(alpha: 0.15)
            : AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline
              ? AppTheme.complete.withValues(alpha: 0.4)
              : AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? AppTheme.complete : AppTheme.tertiaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isOnline ? 'ONLINE' : 'OFFLINE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isOnline ? AppTheme.complete : AppTheme.primaryColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

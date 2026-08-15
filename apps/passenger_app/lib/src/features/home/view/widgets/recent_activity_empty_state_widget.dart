import 'package:flutter/material.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';

class RecentActivityEmptyStateWidget extends StatelessWidget {
  const RecentActivityEmptyStateWidget({required this.isGuest, super.key});

  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isGuest ? 'Guest mode' : 'No recent trips yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isGuest
                  ? 'Sign in to view your recent trips.'
                  : 'Your recent ride history will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

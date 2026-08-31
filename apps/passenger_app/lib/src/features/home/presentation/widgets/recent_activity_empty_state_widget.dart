import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.colorScheme.onSurface,
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
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

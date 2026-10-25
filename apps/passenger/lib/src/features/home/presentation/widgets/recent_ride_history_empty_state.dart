import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class const RecentRideHistoryEmptyState({required this.isGuest, super.key})
    extends StatelessWidget {
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
              isGuest ? 'Your trips, in one place' : 'No recent trips yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isGuest
                  ? 'Sign in or create an account to book rides and keep your trip history here.'
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

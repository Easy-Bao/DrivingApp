import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class const InboxEmptyStateWidget({super.key, this.isGuest = false})
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
              isGuest ? 'Guest mode' : 'No notifications yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isGuest
                  ? 'Sign in to see ride updates and receipts.'
                  : "We'll notify you about rides and account activity.",
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

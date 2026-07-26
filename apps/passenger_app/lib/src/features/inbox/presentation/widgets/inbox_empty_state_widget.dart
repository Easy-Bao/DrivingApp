import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_ui/shared_ui.dart';

class InboxEmptyStateWidget extends StatelessWidget {
  const InboxEmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.bell_off,
              size: 48,
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            const Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "We'll notify you about rides and account activity.",
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

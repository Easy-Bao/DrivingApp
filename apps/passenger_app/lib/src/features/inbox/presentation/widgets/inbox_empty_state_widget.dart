import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_ui/shared_ui.dart';

class InboxEmptyStateWidget extends StatelessWidget {
  const InboxEmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
            child: Icon(
              LucideIcons.bell_off,
              size: 36,
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll notify you about rides and account activity",
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

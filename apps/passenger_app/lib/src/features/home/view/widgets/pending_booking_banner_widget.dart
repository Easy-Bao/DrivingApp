import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';

class PendingBookingBannerWidget extends StatelessWidget {
  final bool isAuthenticated;
  final String destinationName;
  final VoidCallback onContinue;
  final VoidCallback onDismiss;

  const PendingBookingBannerWidget({
    super.key,
    required this.isAuthenticated,
    required this.destinationName,
    required this.onContinue,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAuthenticated) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.secondaryColor),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.route, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Continue your booking',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  destinationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.primaryColor.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onContinue, child: const Text('Continue')),
          IconButton(
            tooltip: 'Dismiss booking draft',
            onPressed: onDismiss,
            icon: const Icon(LucideIcons.x, size: 18),
          ),
        ],
      ),
    );
  }
}

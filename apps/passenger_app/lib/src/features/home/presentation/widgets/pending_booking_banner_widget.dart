import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:design_system/design_system.dart';

class const PendingBookingBannerWidget({
  super.key,
  required this.isAuthenticated,
  required this.destinationName,
  required this.onContinue,
  required this.onDismiss,
}) extends StatelessWidget {
  final bool isAuthenticated;
  final String destinationName;
  final VoidCallback onContinue;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    if (!isAuthenticated) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      decoration: BoxDecoration(
        color: context.colorScheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colorScheme.secondaryContainer),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.route,
            size: 20,
            color: context.colorScheme.onSurface,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue your booking',
                  style: TextStyle(
                    color: context.colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  destinationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.7),
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

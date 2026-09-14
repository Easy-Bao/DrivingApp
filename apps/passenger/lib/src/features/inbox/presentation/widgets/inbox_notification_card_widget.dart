import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger/src/features/inbox/domain/entities/inbox_notification.dart';

class const InboxNotificationCardWidget({
  super.key,
  required this.notification,
  required this.onTap,
}) extends StatelessWidget {
  final InboxNotification notification;
  final VoidCallback onTap;

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (dateToCheck == today) {
      final hourNum = timestamp.hour > 12
          ? timestamp.hour - 12
          : (timestamp.hour == 0 ? 12 : timestamp.hour);
      final periodStr = timestamp.hour >= 12 ? 'PM' : 'AM';
      final minuteStr = timestamp.minute.toString().padLeft(2, '0');
      return '$hourNum:$minuteStr $periodStr';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[timestamp.month - 1]} ${timestamp.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReceipt =
        notification.type == 'ride' ||
        notification.title.toLowerCase().contains('receipt');
    final isDriverChat =
        notification.type == 'driver' || notification.type == 'chat';

    final Color bgCircleColor;
    final Color iconColor;
    final IconData icon;

    if (isDriverChat) {
      bgCircleColor = context.colorScheme.primaryContainer;
      iconColor = context.colorScheme.primary;
      icon = LucideIcons.user;
    } else if (isReceipt) {
      bgCircleColor = context.colorScheme.tertiaryContainer;
      iconColor = context.colorScheme.onTertiaryContainer;
      icon = LucideIcons.receipt;
    } else {
      bgCircleColor = context.colorScheme.surfaceContainerHighest;
      iconColor = context.colorScheme.onSurfaceVariant;
      icon = LucideIcons.bell;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(EasyRideSpacing.lg),
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(EasyRideRadius.lg),
            border: Border.all(color: context.colorScheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: EasyRideSize.minimumTouchTarget,
                height: EasyRideSize.minimumTouchTarget,
                decoration: BoxDecoration(
                  color: bgCircleColor,
                  borderRadius: BorderRadius.circular(EasyRideRadius.md),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: EasyRideSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
                      style: context.textStyles.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: context.textStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTimestamp(notification.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!notification.isRead) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: context.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

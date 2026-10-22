import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger/src/features/inbox/domain/entities/inbox_notification.dart';

class InboxNotificationCard extends StatelessWidget {
  const InboxNotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final InboxNotification notification;
  final VoidCallback onTap;

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(local.year, local.month, local.day);

    if (dateToCheck == today) {
      final twelveHourValue = local.hour > 12
          ? local.hour - 12
          : (local.hour == 0 ? 12 : local.hour);
      final meridiemPeriod = local.hour >= 12 ? 'PM' : 'AM';
      final paddedMinute = local.minute.toString().padLeft(2, '0');
      return '$twelveHourValue:$paddedMinute $meridiemPeriod';
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
      return '${months[local.month - 1]} ${local.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Existing Inbox records still contain the earlier, longer wording.
    final message = notification.title == 'No nearby driver found'
        ? notification.message.replaceFirst(
            ' Your request has expired. Please try searching again.',
            '',
          )
        : notification.message;
    final isReceipt =
        notification.type == 'ride' ||
        notification.title.toLowerCase().contains('receipt');
    final isDriverChat =
        notification.type == 'driver' || notification.type == 'chat';

    final Color circleBackgroundColor;
    final Color iconColor;
    final IconData icon;

    if (isDriverChat) {
      circleBackgroundColor = context.colorScheme.primaryContainer;
      iconColor = context.colorScheme.primary;
      icon = LucideIcons.user;
    } else if (isReceipt) {
      circleBackgroundColor = context.colorScheme.tertiaryContainer;
      iconColor = context.colorScheme.onTertiaryContainer;
      icon = LucideIcons.receipt;
    } else {
      circleBackgroundColor = context.colorScheme.surfaceContainerHighest;
      iconColor = context.colorScheme.onSurfaceVariant;
      icon = LucideIcons.bell;
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: BorderSide(color: context.colorScheme.outlineVariant),
    );

    return Semantics(
      button: true,
      label: '${notification.title}. $message',
      hint: 'Opens notification',
      child: Material(
        color: context.colorScheme.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: AppSize.minimumTouchTarget,
                  height: AppSize.minimumTouchTarget,
                  decoration: BoxDecoration(
                    color: circleBackgroundColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: AppSpacing.lg),
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
                      Text(message, style: context.textStyles.bodySmall),
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
      ),
    );
  }
}

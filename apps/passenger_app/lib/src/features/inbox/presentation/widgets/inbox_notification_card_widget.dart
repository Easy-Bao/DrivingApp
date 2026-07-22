import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:shared_ui/shared_ui.dart';

class InboxNotificationCardWidget extends StatelessWidget {
  final InboxNotification notification;
  final VoidCallback onTap;

  const InboxNotificationCardWidget({
    super.key,
    required this.notification,
    required this.onTap,
  });

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
      bgCircleColor = AppTheme.secondaryColor;
      iconColor = const Color(0xFF8A4F35);
      icon = LucideIcons.user;
    } else if (isReceipt) {
      bgCircleColor = AppTheme.primaryColor;
      iconColor = Colors.white;
      icon = LucideIcons.receipt;
    } else {
      bgCircleColor = AppTheme.neutralColor;
      iconColor = AppTheme.primaryColor;
      icon = LucideIcons.bell;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.neutralColor.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.borderSide.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgCircleColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryColor.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
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
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!notification.isRead) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.cancel,
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

import 'package:passenger/src/features/inbox/domain/entities/inbox_notification.dart';

enum InboxFilter { all, unread, messages, rides }

enum InboxNotificationCategory { message, receipt, ride, general }

final class InboxPresenter(
  DateTime referenceTime, {
  this.alwaysUse24HourFormat = false,
}) {
  final DateTime referenceTime;
  final bool alwaysUse24HourFormat;

  this : referenceTime = referenceTime.toLocal();

  InboxNotificationCategory categoryOf(InboxNotification notification) {
    if (notification.type == 'driver' || notification.type == 'chat') {
      return InboxNotificationCategory.message;
    }
    final title = notification.title.toLowerCase();
    final message = notification.message.toLowerCase();
    if (title.contains('receipt') || message.contains('receipt')) {
      return InboxNotificationCategory.receipt;
    }
    if (notification.type == 'ride') {
      return InboxNotificationCategory.ride;
    }
    return InboxNotificationCategory.general;
  }

  bool isOpenableChat(InboxNotification notification) {
    return notification.type == 'chat' &&
        notification.roomId != null &&
        notification.userId != null &&
        notification.peerId != null;
  }

  String normalizedMessage(InboxNotification notification) {
    if (notification.title == 'No nearby driver found') {
      return notification.message.replaceFirst(
        ' Your request has expired. Please try searching again.',
        '',
      );
    }
    return notification.message;
  }

  int unreadCount(List<InboxNotification> notifications) {
    return notifications.where((item) => !item.isRead).length;
  }

  List<InboxNotification> filter(
    List<InboxNotification> notifications,
    InboxFilter filter,
  ) {
    return switch (filter) {
      InboxFilter.all => notifications,
      InboxFilter.unread =>
        notifications.where((item) => !item.isRead).toList(),
      InboxFilter.messages =>
        notifications
            .where((item) => item.type == 'chat' || item.type == 'driver')
            .toList(),
      InboxFilter.rides =>
        notifications.where((item) => item.type == 'ride').toList(),
    };
  }

  Map<String, List<InboxNotification>> groupByDate(
    List<InboxNotification> notifications,
  ) {
    final grouped = <String, List<InboxNotification>>{};
    for (final notification in notifications) {
      final label = dateGroupLabel(notification.timestamp);
      grouped.putIfAbsent(label, () => <InboxNotification>[]).add(notification);
    }
    return grouped;
  }

  String dateGroupLabel(DateTime timestamp) {
    final local = timestamp.toLocal();
    final today = DateTime(
      referenceTime.year,
      referenceTime.month,
      referenceTime.day,
    );
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(local.year, local.month, local.day);

    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return 'Earlier';
  }

  String formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    final today = DateTime(
      referenceTime.year,
      referenceTime.month,
      referenceTime.day,
    );
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(local.year, local.month, local.day);

    if (date == today) {
      return _formatClockTime(local);
    }
    if (date == yesterday) {
      return 'Yesterday';
    }
    final shortDate = '${_monthNames[local.month - 1]} ${local.day}';
    if (local.year != referenceTime.year) {
      return '$shortDate, ${local.year}';
    }
    return shortDate;
  }

  String formatFullTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    final today = DateTime(
      referenceTime.year,
      referenceTime.month,
      referenceTime.day,
    );
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(local.year, local.month, local.day);
    final time = _formatClockTime(local);

    if (date == today) return 'Today · $time';
    if (date == yesterday) return 'Yesterday · $time';
    final shortDate = '${_monthNames[local.month - 1]} ${local.day}';
    if (local.year != referenceTime.year) {
      return '$shortDate, ${local.year} · $time';
    }
    return '$shortDate · $time';
  }

  String _formatClockTime(DateTime local) {
    final paddedMinute = local.minute.toString().padLeft(2, '0');
    if (alwaysUse24HourFormat) {
      return '${local.hour.toString().padLeft(2, '0')}:$paddedMinute';
    }
    final twelveHourValue = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final meridiemPeriod = local.hour >= 12 ? 'PM' : 'AM';
    return '$twelveHourValue:$paddedMinute $meridiemPeriod';
  }
}

const _monthNames = <String>[
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

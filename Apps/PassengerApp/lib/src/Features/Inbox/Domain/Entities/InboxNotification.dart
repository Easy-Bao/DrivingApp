import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/inbox_notification.freezed.dart';
part 'generated/inbox_notification.g.dart';

@freezed
abstract class InboxNotification with _$InboxNotification {
  const factory InboxNotification({
    required String id,
    required String title,
    required String message,
    required DateTime timestamp,
    required String type,
    required bool isRead,
  }) = _InboxNotification;

  factory InboxNotification.fromJson(Map<String, dynamic> json) =>
      _$InboxNotificationFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/notification_model.freezed.dart';
part 'generated/notification_model.g.dart';

/// NotificationModel represents a system or transactional alert notification.
@freezed
abstract class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    required String title,
    required String message,
    required DateTime timestamp,
    @Default('system') String type,
    @Default(false) bool isRead,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
}

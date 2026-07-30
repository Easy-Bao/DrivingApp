// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../inbox_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InboxNotification _$InboxNotificationFromJson(Map<String, dynamic> json) =>
    _InboxNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: json['type'] as String,
      isRead: json['isRead'] as bool,
    );

Map<String, dynamic> _$InboxNotificationToJson(_InboxNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'message': instance.message,
      'timestamp': instance.timestamp.toIso8601String(),
      'type': instance.type,
      'isRead': instance.isRead,
    };

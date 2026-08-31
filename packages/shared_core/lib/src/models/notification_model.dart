import 'package:equatable/equatable.dart';
import 'package:foundation/src/utils/safe_parse.dart';

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.type = 'system',
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: SafeParse.toStringValue(json['id']),
      title: SafeParse.toStringValue(json['title']),
      message: SafeParse.toStringValue(json['message'] ?? json['body']),
      timestamp:
          DateTime.tryParse(
            SafeParse.toStringValue(json['timestamp'] ?? json['created_at']),
          ) ??
          DateTime.now(),
      type: SafeParse.toStringValue(json['type'], 'system'),
      isRead: _toBool(json['isRead'] ?? json['is_read']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'isRead': isRead,
    };
  }

  @override
  List<Object?> get props => [id, title, message, timestamp, type, isRead];
}

bool _toBool(Object? value) {
  if (value is bool) return value;
  return value?.toString().toLowerCase() == 'true';
}

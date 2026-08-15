import 'package:equatable/equatable.dart';
import 'package:shared_core/shared_core.dart';

class InboxNotification extends Equatable {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type;
  final bool isRead;

  const InboxNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.isRead,
  });

  InboxNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    String? type,
    bool? isRead,
  }) {
    return InboxNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }

  factory InboxNotification.fromJson(Map<String, dynamic> json) {
    return InboxNotification(
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

import 'package:equatable/equatable.dart';

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
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      type: json['type'] as String? ?? 'system',
      isRead: json['isRead'] as bool? ?? false,
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

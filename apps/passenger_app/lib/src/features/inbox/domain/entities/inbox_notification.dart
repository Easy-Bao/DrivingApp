import 'package:equatable/equatable.dart';
import 'package:foundation/foundation.dart';

class InboxNotification extends Equatable {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type;
  final bool isRead;
  final String? roomId;
  final String? peerId;
  final String? peerName;
  final String? userId;
  final DateTime? expiresAt;

  const InboxNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.isRead,
    this.roomId,
    this.peerId,
    this.peerName,
    this.userId,
    this.expiresAt,
  });

  bool get isExpired =>
      expiresAt != null && !expiresAt!.isAfter(DateTime.now());

  InboxNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    String? type,
    bool? isRead,
    String? roomId,
    String? peerId,
    String? peerName,
    String? userId,
    DateTime? expiresAt,
  }) {
    return InboxNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      roomId: roomId ?? this.roomId,
      peerId: peerId ?? this.peerId,
      peerName: peerName ?? this.peerName,
      userId: userId ?? this.userId,
      expiresAt: expiresAt ?? this.expiresAt,
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
      roomId: _nullableString(json['roomId'] ?? json['room_id']),
      peerId: _nullableString(json['peerId'] ?? json['peer_id']),
      peerName: _nullableString(json['peerName'] ?? json['peer_name']),
      userId: _nullableString(json['userId'] ?? json['user_id']),
      expiresAt: _parseDate(json['expiresAt'] ?? json['expires_at']),
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
      if (roomId != null) 'roomId': roomId,
      if (peerId != null) 'peerId': peerId,
      if (peerName != null) 'peerName': peerName,
      if (userId != null) 'userId': userId,
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    title,
    message,
    timestamp,
    type,
    isRead,
    roomId,
    peerId,
    peerName,
    userId,
    expiresAt,
  ];
}

String? _nullableString(Object? value) {
  final normalized = SafeParse.toStringValue(value).trim();
  return normalized.isEmpty ? null : normalized;
}

DateTime? _parseDate(Object? value) {
  final normalized = SafeParse.toStringValue(value).trim();
  return normalized.isEmpty ? null : DateTime.tryParse(normalized);
}

bool _toBool(Object? value) {
  if (value is bool) return value;
  return value?.toString().toLowerCase() == 'true';
}

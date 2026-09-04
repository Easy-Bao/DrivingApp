import 'package:equatable/equatable.dart';
import 'package:passenger/src/features/chat/domain/entities/chat_message.dart';

class const ChatMessageDto({
  this.id = '',
  required this.text,
  required this.senderId,
  required this.createdAt,
  this.deliveryStatus = ChatMessageDeliveryStatus.delivered,
}) extends Equatable {
  final String id;
  final String text;
  final String senderId;
  final DateTime createdAt;
  final ChatMessageDeliveryStatus deliveryStatus;

  factory fromJson(Map<String, dynamic> json) {
    final {
      'id': rawId,
      'text': rawText,
      'sender_id': rawSenderId,
      'created_at': rawCreatedAt,
      'delivery_status': rawDeliveryStatus,
    } = _canonicalPayload(
      json,
    );

    final text = _readString(rawText, 'text');
    final senderId = _readSenderId(rawSenderId);
    final createdAt = _readDateTime(rawCreatedAt, 'created_at');
    final suppliedId = rawId;
    final id = suppliedId is String && suppliedId.trim().isNotEmpty
        ? suppliedId.trim()
        : 'legacy:$senderId:${createdAt.toUtc().toIso8601String()}:$text';

    return ChatMessageDto(
      id: id,
      text: text,
      senderId: senderId,
      createdAt: createdAt,
      deliveryStatus: _deliveryStatus(rawDeliveryStatus),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'senderId': senderId,
      'createdAt': createdAt.toIso8601String(),
      'deliveryStatus': deliveryStatus.name,
    };
  }

  ChatMessage toEntity({required String currentUserId}) {
    return ChatMessage(
      id: id,
      text: text,
      senderId: senderId,
      isFromPeer: senderId != currentUserId,
      createdAt: createdAt.toLocal(),
      deliveryStatus: deliveryStatus,
    );
  }

  @override
  List<Object?> get props => [id, text, senderId, createdAt, deliveryStatus];
}

Map<String, Object?> _canonicalPayload(Map<String, dynamic> json) => {
  'id': json['id'] ?? json['messageId'] ?? json['message_id'],
  'text': json['text'] ?? json['message'],
  'sender_id': json['senderId'] ?? json['sender_id'],
  'created_at': json['createdAt'] ?? json['created_at'],
  'delivery_status': json['deliveryStatus'] ?? json['delivery_status'],
};

String _readString(Object? value, String field) {
  return switch (value) {
    null => '',
    final String text => text,
    _ => throw FormatException('Chat message $field must be a string.'),
  };
}

String _readSenderId(Object? value) {
  return switch (value) {
    null => '',
    final String senderId => senderId,
    final num senderId => senderId.toString(),
    _ => throw const FormatException(
      'Chat message sender_id must be a scalar.',
    ),
  };
}

DateTime _readDateTime(Object? value, String field) {
  return switch (value) {
    null => DateTime.now(),
    final String timestamp => DateTime.tryParse(timestamp) ?? DateTime.now(),
    _ => throw FormatException('Chat message $field must be a string.'),
  };
}

ChatMessageDeliveryStatus _deliveryStatus(Object? value) {
  return switch (value?.toString().trim().toLowerCase()) {
    'sending' => ChatMessageDeliveryStatus.sending,
    'sent' => ChatMessageDeliveryStatus.sent,
    'failed' => ChatMessageDeliveryStatus.failed,
    _ => ChatMessageDeliveryStatus.delivered,
  };
}

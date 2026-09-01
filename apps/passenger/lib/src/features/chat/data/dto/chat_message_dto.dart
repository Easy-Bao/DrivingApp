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

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) {
    final text = json['text'] as String? ?? json['message'] as String? ?? '';
    final senderId =
        json['senderId'] as String? ?? json['sender_id'] as String? ?? '';
    final createdAt =
        DateTime.tryParse(
          json['createdAt'] as String? ?? json['created_at'] as String? ?? '',
        ) ??
        DateTime.now();
    final suppliedId = json['id'] ?? json['messageId'] ?? json['message_id'];
    final id = suppliedId is String && suppliedId.trim().isNotEmpty
        ? suppliedId.trim()
        : 'legacy:$senderId:${createdAt.toUtc().toIso8601String()}:$text';

    return ChatMessageDto(
      id: id,
      text: text,
      senderId: senderId,
      createdAt: createdAt,
      deliveryStatus: _deliveryStatus(
        json['deliveryStatus'] ?? json['delivery_status'],
      ),
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

ChatMessageDeliveryStatus _deliveryStatus(Object? value) {
  return switch (value?.toString().trim().toLowerCase()) {
    'sending' => ChatMessageDeliveryStatus.sending,
    'sent' => ChatMessageDeliveryStatus.sent,
    'failed' => ChatMessageDeliveryStatus.failed,
    _ => ChatMessageDeliveryStatus.delivered,
  };
}

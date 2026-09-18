import 'package:equatable/equatable.dart';

enum ChatMessageDeliveryStatus { sending, sent, delivered, failed }

class const ChatMessage({
  this.id = '',
  required this.text,
  required this.senderId,
  required this.isFromPeer,
  required this.createdAt,
  this.deliveryStatus = ChatMessageDeliveryStatus.delivered,
}) extends Equatable {
  final String id;
  final String text;
  final String senderId;
  final bool isFromPeer;
  final DateTime createdAt;
  final ChatMessageDeliveryStatus deliveryStatus;

  ChatMessage copyWith({ChatMessageDeliveryStatus? deliveryStatus}) {
    return ChatMessage(
      id: id,
      text: text,
      senderId: senderId,
      isFromPeer: isFromPeer,
      createdAt: createdAt,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
    );
  }

  String get identityKey => id.isNotEmpty
      ? 'id:$id'
      : 'legacy:$senderId:${createdAt.toUtc().toIso8601String()}:$text';

  @override
  List<Object?> get props => [
    id,
    text,
    senderId,
    isFromPeer,
    createdAt,
    deliveryStatus,
  ];
}

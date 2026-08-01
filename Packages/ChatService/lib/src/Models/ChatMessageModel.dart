import 'package:chat_service/src/Models/ChatMessage.dart';
import 'package:equatable/equatable.dart';

class ChatMessageModel extends Equatable {
  final String text;
  final String senderId;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.text,
    required this.senderId,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      text: json['text'] as String? ?? json['message'] as String? ?? '',
      senderId: json['senderId'] as String? ?? json['sender_id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'senderId': senderId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ChatMessage toEntity({required String currentUserId}) {
    return ChatMessage(
      text: text,
      senderId: senderId,
      isFromPeer: senderId != currentUserId,
      createdAt: createdAt.toLocal(),
    );
  }

  @override
  List<Object?> get props => [text, senderId, createdAt];
}

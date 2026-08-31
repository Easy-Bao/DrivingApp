import 'package:chat/src/domain/entities/chat_message.dart';

sealed class ChatEvent {
  const ChatEvent();
}

class ChatHistoryReceived extends ChatEvent {
  final List<ChatMessage> messages;

  const ChatHistoryReceived(this.messages);
}

class ChatMessageReceived extends ChatEvent {
  final ChatMessage message;

  const ChatMessageReceived(this.message);
}

class ChatTypingChanged extends ChatEvent {
  final bool isTyping;
  final bool isFromPeer;

  const ChatTypingChanged({required this.isTyping, required this.isFromPeer});
}

class ChatRoomLocked extends ChatEvent {
  final String reason;

  const ChatRoomLocked(this.reason);
}

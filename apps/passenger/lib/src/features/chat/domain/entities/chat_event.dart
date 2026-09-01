import 'package:passenger/src/features/chat/domain/entities/chat_message.dart';

sealed class const ChatEvent() {}

class const ChatHistoryReceived(this.messages) extends ChatEvent {
  final List<ChatMessage> messages;
}

class const ChatMessageReceived(this.message) extends ChatEvent {
  final ChatMessage message;
}

class const ChatTypingChanged({
  required this.isTyping,
  required this.isFromPeer,
}) extends ChatEvent {
  final bool isTyping;
  final bool isFromPeer;
}

class const ChatRoomLocked(this.reason) extends ChatEvent {
  final String reason;
}

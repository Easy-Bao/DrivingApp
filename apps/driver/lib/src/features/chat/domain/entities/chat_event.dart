import 'package:driver/src/features/chat/domain/entities/chat_message.dart';

sealed class const ChatEvent() {}

final class const ChatHistoryReceived(this.messages) extends ChatEvent {
  final List<ChatMessage> messages;
}

final class const ChatMessageReceived(this.message) extends ChatEvent {
  final ChatMessage message;
}

final class const ChatTypingChanged({
  required this.isTyping,
  required this.isFromPeer,
}) extends ChatEvent {
  final bool isTyping;
  final bool isFromPeer;
}

final class const ChatRoomLocked(this.reason) extends ChatEvent {
  final String reason;
}

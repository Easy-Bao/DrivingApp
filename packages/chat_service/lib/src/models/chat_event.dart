import 'package:chat_service/src/models/chat_message.dart';

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

class ChatRoomLocked extends ChatEvent {
  final String reason;

  const ChatRoomLocked(this.reason);
}

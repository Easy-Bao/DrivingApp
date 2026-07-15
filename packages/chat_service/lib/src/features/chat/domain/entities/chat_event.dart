import 'package:chat_service/src/features/chat/domain/entities/chat_message.dart';

/// Sealed class hierarchy representing parsed real-time events in a chat room.
sealed class ChatEvent {
  const ChatEvent();
}

/// Event indicating the complete historical log of messages has been received.
class ChatHistoryReceived extends ChatEvent {
  /// The list of existing messages in the conversation.
  final List<ChatMessage> messages;

  /// Creates a [ChatHistoryReceived] event.
  const ChatHistoryReceived(this.messages);
}

/// Event indicating a new chat message was broadcast.
class ChatMessageReceived extends ChatEvent {
  /// The message entity that was received.
  final ChatMessage message;

  /// Creates a [ChatMessageReceived] event.
  const ChatMessageReceived(this.message);
}

/// Event indicating the chat room was locked.
class ChatRoomLocked extends ChatEvent {
  /// The reason why the conversation room was locked or resolved.
  final String reason;

  /// Creates a [ChatRoomLocked] event.
  const ChatRoomLocked(this.reason);
}

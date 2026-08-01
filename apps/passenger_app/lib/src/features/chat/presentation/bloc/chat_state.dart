import 'package:chat_service/chat_service.dart';
import 'package:equatable/equatable.dart';

class ChatState extends Equatable {
  final List<ChatMessage> messages;
  final bool isConnecting;
  final bool isConnected;
  final bool isRoomLocked;
  final String lockReasonMessage;
  final String? errorMessage;

  const ChatState({
    this.messages = const [],
    this.isConnecting = false,
    this.isConnected = false,
    this.isRoomLocked = false,
    this.lockReasonMessage = 'This chat room has been resolved.',
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isConnecting,
    bool? isConnected,
    bool? isRoomLocked,
    String? lockReasonMessage,
    String? errorMessage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      isRoomLocked: isRoomLocked ?? this.isRoomLocked,
      lockReasonMessage: lockReasonMessage ?? this.lockReasonMessage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        messages,
        isConnecting,
        isConnected,
        isRoomLocked,
        lockReasonMessage,
        errorMessage,
      ];
}

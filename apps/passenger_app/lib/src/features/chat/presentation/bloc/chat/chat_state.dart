import 'package:passenger_app/src/features/chat/chat.dart';
import 'package:equatable/equatable.dart';

class const ChatState({
  this.messages = const [],
  this.isConnecting = false,
  this.isConnected = false,
  this.isRoomLocked = false,
  this.isPeerTyping = false,
  this.lockReasonMessage = 'This chat room has been resolved.',
  this.errorMessage,
  this.lastDeliveredMessage,
}) extends Equatable {
  static const Object _unset = Object();

  final List<ChatMessage> messages;
  final bool isConnecting;
  final bool isConnected;
  final bool isRoomLocked;
  final bool isPeerTyping;
  final String lockReasonMessage;
  final String? errorMessage;
  final ChatMessage? lastDeliveredMessage;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isConnecting,
    bool? isConnected,
    bool? isRoomLocked,
    bool? isPeerTyping,
    String? lockReasonMessage,
    Object? errorMessage = _unset,
    Object? lastDeliveredMessage = _unset,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      isRoomLocked: isRoomLocked ?? this.isRoomLocked,
      isPeerTyping: isPeerTyping ?? this.isPeerTyping,
      lockReasonMessage: lockReasonMessage ?? this.lockReasonMessage,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      lastDeliveredMessage: identical(lastDeliveredMessage, _unset)
          ? this.lastDeliveredMessage
          : lastDeliveredMessage as ChatMessage?,
    );
  }

  @override
  List<Object?> get props => [
    messages,
    isConnecting,
    isConnected,
    isRoomLocked,
    isPeerTyping,
    lockReasonMessage,
    errorMessage,
    lastDeliveredMessage,
  ];
}

import 'package:shared_core/shared_core.dart';
import 'package:equatable/equatable.dart';

class ChatState extends Equatable {
  static const Object _unset = Object();

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
    Object? errorMessage = _unset,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      isRoomLocked: isRoomLocked ?? this.isRoomLocked,
      lockReasonMessage: lockReasonMessage ?? this.lockReasonMessage,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
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

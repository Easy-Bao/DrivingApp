import 'package:equatable/equatable.dart';
import 'package:passenger/src/features/chat/chat.dart';
import 'package:passenger/src/features/chat/domain/entities/chat_peer.dart';

class const ChatState({
  this.messages = const [],
  this.peer,
  this.isSendingImage = false,
  this.isLoadingHistory = false,
  this.isConnecting = false,
  this.isConnected = false,
  this.isRoomLocked = false,
  this.isPeerTyping = false,
  this.lockReasonMessage = 'Chat is closed for this trip.',
  this.errorMessage,
  this.isAccessDenied = false,
  this.lastDeliveredMessage,
}) extends Equatable {
  static const Object _unset = Object();

  final List<ChatMessage> messages;
  final ChatPeer? peer;
  final bool isSendingImage;
  final bool isLoadingHistory;
  final bool isConnecting;
  final bool isConnected;
  final bool isRoomLocked;
  final bool isPeerTyping;
  final String lockReasonMessage;
  final String? errorMessage;
  final bool isAccessDenied;
  final ChatMessage? lastDeliveredMessage;

  ChatState copyWith({
    List<ChatMessage>? messages,
    ChatPeer? peer,
    bool? isSendingImage,
    bool? isLoadingHistory,
    bool? isConnecting,
    bool? isConnected,
    bool? isRoomLocked,
    bool? isPeerTyping,
    String? lockReasonMessage,
    Object? errorMessage = _unset,
    bool? isAccessDenied,
    Object? lastDeliveredMessage = _unset,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      peer: peer ?? this.peer,
      isSendingImage: isSendingImage ?? this.isSendingImage,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isConnecting: isConnecting ?? this.isConnecting,
      isConnected: isConnected ?? this.isConnected,
      isRoomLocked: isRoomLocked ?? this.isRoomLocked,
      isPeerTyping: isPeerTyping ?? this.isPeerTyping,
      lockReasonMessage: lockReasonMessage ?? this.lockReasonMessage,
      isAccessDenied: isAccessDenied ?? this.isAccessDenied,
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
    peer,
    isSendingImage,
    isLoadingHistory,
    isConnecting,
    isConnected,
    isRoomLocked,
    isPeerTyping,
    lockReasonMessage,
    errorMessage,
    isAccessDenied,
    lastDeliveredMessage,
  ];
}

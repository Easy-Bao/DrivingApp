import 'dart:async';
import 'package:chat_service/chat_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:passenger_app/src/core/config/environment_config.dart';

/**
 * State representing connection status and messages in the chat room.
 */
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
  List<Object?> get props => [messages, isConnecting, isConnected, isRoomLocked, lockReasonMessage, errorMessage];
}

/**
 * Cubit responsible for managing socket connections, messaging streams,
 * and resolving the chat room session. Decouples chat views from API and WS logic.
 */
class ChatCubit extends Cubit<ChatState> {
  final ChatService _chatService;
  StreamSubscription? _chatSubscription;

  ChatCubit({required String currentUserId})
      : _chatService = ChatService(currentUserId: currentUserId),
        super(const ChatState()) {
    _chatSubscription = _chatService.chatUpdatesStream.listen((_) {
      emit(state.copyWith(
        messages: List.from(_chatService.chatHistoryMessages),
        isConnected: _chatService.isConnectionActive,
        isRoomLocked: _chatService.isRoomLocked,
        lockReasonMessage: _chatService.lockReasonMessage,
      ));
    });
  }

  /**
   * Initiates socket handshake with the chat service for [roomId].
   */
  Future<void> connect(String roomId, Uri wsUri) async {
    emit(state.copyWith(isConnecting: true));
    try {
      await _chatService.connectToChatRoom(roomId: roomId, chatUri: wsUri);
      emit(state.copyWith(
        isConnecting: false,
        isConnected: _chatService.isConnectionActive,
        isRoomLocked: _chatService.isRoomLocked,
        lockReasonMessage: _chatService.lockReasonMessage,
        messages: List.from(_chatService.chatHistoryMessages),
      ));
    } catch (e, stackTrace) {
      debugPrint('Error connecting to chat room: $e\n$stackTrace');
      emit(state.copyWith(isConnecting: false, errorMessage: e.toString()));
    }
  }

  /**
   * Dispatches a text message to the socket if room is active.
   */
  void sendMessage(String text) {
    if (state.isRoomLocked) return;
    if (text.trim().isEmpty) return;

    if (_chatService.isConnectionActive) {
      _chatService.sendMessageToRoom(text);
    }
  }

  /**
   * Resolves/locks the chat room by hitting the HTTP gateway.
   */
  Future<void> resolveChatRoom(String roomId, String userId, Uri wsUri) async {
    try {
      final gatewayUrl = EnvironmentConfig.httpBaseUrl;
      final resolveEndpointUrl = '$gatewayUrl/chat/rooms/$roomId/resolve';
      final response = await http.post(
        Uri.parse(resolveEndpointUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await _chatService.connectToChatRoom(roomId: roomId, chatUri: wsUri);
      }
    } catch (e, stackTrace) {
      debugPrint('Error resolving chat room in cubit: $e\n$stackTrace');
    }
  }

  @override
  Future<void> close() {
    unawaited(_chatSubscription?.cancel());
    unawaited(_chatService.disconnectChatRoom());
    return super.close();
  }
}

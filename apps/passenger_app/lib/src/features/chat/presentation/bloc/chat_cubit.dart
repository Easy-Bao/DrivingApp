import 'dart:async';

import 'package:chat_service/chat_service.dart';
import 'package:core_models/core_models.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:session_service/session_service.dart';

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

class ChatCubit extends Cubit<ChatState> {
  final ChatService _chatService;
  StreamSubscription? _chatSubscription;

  ChatCubit({required String currentUserId})
    : _chatService = ChatService(currentUserId: currentUserId),
      super(const ChatState()) {
    _chatSubscription = _chatService.chatUpdatesStream.listen((_) {
      emit(
        state.copyWith(
          messages: List.from(_chatService.chatHistoryMessages),
          isConnected: _chatService.isConnectionActive,
          isRoomLocked: _chatService.isRoomLocked,
          lockReasonMessage: _chatService.lockReasonMessage,
        ),
      );
    });
  }

  Future<void> connect(String roomId, Uri wsUri) async {
    emit(state.copyWith(isConnecting: true));
    try {
      await _chatService.connectToChatRoom(roomId: roomId, chatUri: wsUri);
      emit(
        state.copyWith(
          isConnecting: false,
          isConnected: _chatService.isConnectionActive,
          isRoomLocked: _chatService.isRoomLocked,
          lockReasonMessage: _chatService.lockReasonMessage,
          messages: List.from(_chatService.chatHistoryMessages),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Error connecting to chat room: $error\n$stackTrace');
      emit(
        state.copyWith(
          isConnecting: false,
          errorMessage: ErrorHandler.getErrorMessage(error),
        ),
      );
    }
  }

  void sendMessage(String text) {
    if (state.isRoomLocked) return;
    if (text.trim().isEmpty) return;

    if (_chatService.isConnectionActive) {
      _chatService.sendMessageToRoom(text);
    }
  }

  Future<void> resolveChatRoom(String roomId, String userId, Uri wsUri) async {
    try {
      final gatewayUri = EnvironmentConfig.httpBaseUri;
      final resolveEndpointUri = gatewayUri.replace(
        path: '/chat/rooms/$roomId/resolve',
      );
      final response = await Dio().postUri(
        resolveEndpointUri,
      );

      if (response.statusCode == 200) {
        await _chatService.connectToChatRoom(roomId: roomId, chatUri: wsUri);
      }
    } catch (error, stackTrace) {
      debugPrint('Error resolving chat room in cubit: $error\n$stackTrace');
    }
  }

  @override
  Future<void> close() {
    unawaited(_chatSubscription?.cancel());
    unawaited(_chatService.disconnectChatRoom());
    return super.close();
  }
}

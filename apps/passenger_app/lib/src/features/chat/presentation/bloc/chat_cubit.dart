import 'dart:async';
import 'dart:developer' as dev;

import 'package:chat_service/chat_service.dart';
import 'package:core_models/core_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/chat/presentation/bloc/chat_state.dart';
import 'package:session_service/session_service.dart';

export 'package:passenger_app/src/features/chat/presentation/bloc/chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatService _chatService;
  StreamSubscription<void>? _chatSubscription;

  ChatCubit({required ChatService chatService})
      : _chatService = chatService,
        super(const ChatState());

  Future<void> connectToChatRoom({
    required String roomId,
    required Uri wsUri,
  }) async {
    emit(state.copyWith(isConnecting: true, errorMessage: null));

    try {
      await _chatService.connectToChatRoom(roomId: roomId, chatUri: wsUri);
      unawaited(_chatSubscription?.cancel());
      _chatSubscription = _chatService.chatUpdatesStream.listen(
        (_) {
          emit(
            state.copyWith(
              messages: _chatService.chatHistoryMessages,
              isRoomLocked: _chatService.isRoomLocked,
              lockReasonMessage: _chatService.lockReasonMessage,
            ),
          );
        },
        onError: (error) {
          emit(
            state.copyWith(
              errorMessage: ErrorHandler.getErrorMessage(error),
            ),
          );
        },
      );

      emit(
        state.copyWith(
          isConnecting: false,
          isConnected: true,
          messages: _chatService.chatHistoryMessages,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isConnecting: false,
          isConnected: false,
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
      dev.log('Error resolving chat room in cubit: $error\n$stackTrace');
    }
  }

  @override
  Future<void> close() {
    unawaited(_chatSubscription?.cancel());
    unawaited(_chatService.disconnectChatRoom());
    return super.close();
  }
}

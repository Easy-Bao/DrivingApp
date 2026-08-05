import 'dart:async';
import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/core/constants/env_config.dart';
import 'package:passenger_app/src/features/chat/presentation/bloc/chat_state.dart';
import 'package:shared_core/shared_core.dart';

export 'package:passenger_app/src/features/chat/presentation/bloc/chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final IChatRepository _chatRepository;
  StreamSubscription? _chatSubscription;

  ChatCubit({required IChatRepository chatRepository})
    : _chatRepository = chatRepository,
      super(const ChatState());

  Future<void> connectToChatRoom({
    required String roomId,
    required Uri wsUri,
    String? token,
  }) async {
    emit(state.copyWith(isConnecting: true, errorMessage: null));

    try {
      final connResult = await _chatRepository.establishChatConnection(
        roomId: roomId,
        chatUri: wsUri,
        token: token,
      );

      connResult.fold(
        (failure) {
          emit(
            state.copyWith(
              isConnecting: false,
              isConnected: false,
              errorMessage: failure.message,
            ),
          );
        },
        (_) {
          unawaited(_chatSubscription?.cancel());
          _chatSubscription = _chatRepository.chatEventsStream.listen(
            (eitherEvent) {
              eitherEvent.fold(
                (failure) =>
                    emit(state.copyWith(errorMessage: failure.message)),
                (chatEvent) {
                  if (chatEvent is ChatHistoryReceived) {
                    emit(state.copyWith(messages: chatEvent.messages));
                  } else if (chatEvent is ChatMessageReceived) {
                    final updated = List<ChatMessage>.from(state.messages)
                      ..add(chatEvent.message);
                    emit(state.copyWith(messages: updated));
                  } else if (chatEvent is ChatRoomLocked) {
                    emit(
                      state.copyWith(
                        isRoomLocked: true,
                        lockReasonMessage: chatEvent.reason,
                      ),
                    );
                  }
                },
              );
            },
            onError: (error) {
              emit(state.copyWith(errorMessage: 'Chat stream error: $error'));
            },
          );

          emit(state.copyWith(isConnecting: false, isConnected: true));
        },
      );
    } catch (error) {
      emit(
        state.copyWith(
          isConnecting: false,
          isConnected: false,
          errorMessage: 'Failed to connect: $error',
        ),
      );
    }
  }

  Future<bool> sendMessage(String text) async {
    if (state.isRoomLocked || text.trim().isEmpty) return false;

    if (!_chatRepository.isSessionConnected) return false;
    final result = await _chatRepository.sendChatMessage(text);
    return result.isRight();
  }

  Future<void> resolveChatRoom(
    String roomId,
    String userId,
    Uri wsUri, {
    String? token,
  }) async {
    try {
      final gatewayUri = EnvConfig.passengerServiceUri;
      final resolveEndpointUri = gatewayUri.replace(
        path: '/api/v1/chat/rooms/$roomId/resolve',
      );
      final response = await Dio().postUri(resolveEndpointUri);

      if (response.statusCode == 200) {
        await connectToChatRoom(roomId: roomId, wsUri: wsUri, token: token);
      }
    } catch (error, stackTrace) {
      dev.log('Error resolving chat room in cubit: $error\n$stackTrace');
    }
  }

  @override
  Future<void> close() {
    unawaited(_chatSubscription?.cancel());
    unawaited(_chatRepository.terminateChatConnection());
    return super.close();
  }
}

import 'dart:async';
import 'dart:developer' as dev;

import 'package:chat_service/ChatService.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/Core/Constants/EnvConfig.dart';
import 'package:passenger_app/src/Features/Chat/Presentation/Bloc/ChatState.dart';

export 'package:passenger_app/src/Features/Chat/Presentation/Bloc/ChatState.dart';

class ChatCubit extends Cubit<ChatState> {
  final IChatRepository _chatRepository;
  StreamSubscription? _chatSubscription;

  ChatCubit({required IChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(const ChatState());

  Future<void> connectToChatRoom({
    required String roomId,
    required Uri wsUri,
  }) async {
    emit(state.copyWith(isConnecting: true, errorMessage: null));

    try {
      final connResult = await _chatRepository.establishChatConnection(
        roomId: roomId,
        chatUri: wsUri,
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
                (failure) => emit(state.copyWith(errorMessage: failure.message)),
                (chatEvent) {
                  if (chatEvent is ChatHistoryReceived) {
                    emit(state.copyWith(messages: chatEvent.messages));
                  } else if (chatEvent is ChatMessageReceived) {
                    final updated = List<ChatMessage>.from(state.messages)..add(chatEvent.message);
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
              emit(
                state.copyWith(
                  errorMessage: 'Chat stream error: $error',
                ),
              );
            },
          );

          emit(
            state.copyWith(
              isConnecting: false,
              isConnected: true,
            ),
          );
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

  void sendMessage(String text) {
    if (state.isRoomLocked) return;
    if (text.trim().isEmpty) return;

    if (_chatRepository.isSessionConnected) {
      unawaited(_chatRepository.sendChatMessage(text));
    }
  }

  Future<void> resolveChatRoom(String roomId, String userId, Uri wsUri) async {
    try {
      final gatewayUri = EnvConfig.passengerServiceUri;
      final resolveEndpointUri = gatewayUri.replace(
        path: '/chat/rooms/$roomId/resolve',
      );
      final response = await Dio().postUri(
        resolveEndpointUri,
      );

      if (response.statusCode == 200) {
        await connectToChatRoom(roomId: roomId, wsUri: wsUri);
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

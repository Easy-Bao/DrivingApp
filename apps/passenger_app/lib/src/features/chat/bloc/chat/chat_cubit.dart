import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/chat/bloc/chat/chat_state.dart';
import 'package:shared_core/shared_core.dart';

export 'package:passenger_app/src/features/chat/bloc/chat/chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final IChatRepository _chatRepository;
  StreamSubscription? _chatSubscription;

  ChatCubit({required IChatRepository chatRepository})
    : _chatRepository = chatRepository,
      super(const ChatState());

  Future<bool> initializeChatRoom({
    required String roomId,
    required String passengerId,
    required String driverId,
  }) async {
    final result = await _chatRepository.initializeChatRoom(
      roomId: roomId,
      passengerId: passengerId,
      driverId: driverId,
    );
    return result.fold((failure) {
      if (!isClosed) {
        emit(state.copyWith(errorMessage: failure.message));
      }
      return false;
    }, (_) => true);
  }

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
            onError: (_) {
              emit(state.copyWith(errorMessage: 'Chat stream unavailable.'));
            },
          );

          emit(state.copyWith(isConnecting: false, isConnected: true));
          unawaited(_loadHistory(roomId));
        },
      );
    } catch (_) {
      emit(
        state.copyWith(
          isConnecting: false,
          isConnected: false,
          errorMessage: 'Unable to connect to chat.',
        ),
      );
    }
  }

  Future<void> _loadHistory(String roomId) async {
    final result = await _chatRepository.fetchRoomMessages(roomId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (messages) => emit(state.copyWith(messages: messages)),
    );
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
      final result = await _chatRepository.resolveChatRoom(roomId);
      await result.fold(
        (failure) async =>
            dev.log('Unable to resolve chat room: ${failure.runtimeType}'),
        (_) => connectToChatRoom(roomId: roomId, wsUri: wsUri, token: token),
      );
    } catch (_) {
      dev.log('Unable to resolve chat room.');
    }
  }

  @override
  Future<void> close() async {
    await _chatSubscription?.cancel();
    await _chatRepository.terminateChatConnection();
    await _chatRepository.dispose();
    return super.close();
  }
}

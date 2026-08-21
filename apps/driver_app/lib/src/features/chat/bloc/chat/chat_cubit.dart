import 'dart:async';
import 'package:shared_core/shared_core.dart';
import 'package:driver_app/src/features/chat/data/datasources/chat_room_remote_data_source.dart';
import 'package:driver_app/src/features/chat/bloc/chat/chat_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'package:driver_app/src/features/chat/bloc/chat/chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final IChatRepository _chatRepository;
  final ChatRoomRemoteDataSource _roomRemoteDataSource;
  StreamSubscription? _chatSubscription;

  ChatCubit({
    required IChatRepository chatRepository,
    required ChatRoomRemoteDataSource roomRemoteDataSource,
  }) : _chatRepository = chatRepository,
       _roomRemoteDataSource = roomRemoteDataSource,
       super(const ChatState());

  Future<bool> initializeChatRoom({
    required String roomId,
    required String driverId,
    required String passengerId,
  }) async {
    try {
      final initializationStatus = await _roomRemoteDataSource.initializeRoom(
        roomId: roomId,
        driverId: driverId,
        passengerId: passengerId,
      );
      if (initializationStatus == ChatRoomInitializationStatus.resolved) {
        if (!isClosed) {
          emit(
            state.copyWith(
              isConnecting: false,
              isConnected: false,
              isRoomLocked: true,
              lockReasonMessage: 'This chat has already been resolved.',
              errorMessage: null,
            ),
          );
        }
        return false;
      }
      if (initializationStatus == ChatRoomInitializationStatus.unavailable &&
          !isClosed) {
        emit(
          state.copyWith(
            isConnecting: false,
            errorMessage: 'Chat is unavailable right now. Please try again.',
          ),
        );
      }
      return initializationStatus == ChatRoomInitializationStatus.opened;
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            isConnecting: false,
            errorMessage: 'Chat is unavailable right now. Please try again.',
          ),
        );
      }
      return false;
    }
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
              errorMessage: ErrorHandler.getErrorMessage(failure),
            ),
          );
        },
        (_) {
          unawaited(_chatSubscription?.cancel());
          _chatSubscription = _chatRepository.chatEventsStream.listen(
            (eitherEvent) {
              eitherEvent.fold(
                (failure) => emit(
                  state.copyWith(
                    errorMessage: ErrorHandler.getErrorMessage(failure),
                  ),
                ),
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
      (failure) => emit(
        state.copyWith(errorMessage: ErrorHandler.getErrorMessage(failure)),
      ),
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
      final resolved = await _roomRemoteDataSource.resolveRoom(roomId);
      if (resolved) {
        await _chatSubscription?.cancel();
        await _chatRepository.terminateChatConnection();
        if (!isClosed) {
          emit(
            state.copyWith(
              isConnected: false,
              isRoomLocked: true,
              lockReasonMessage: 'This chat is closed.',
              errorMessage: null,
            ),
          );
        }
      } else if (!isClosed) {
        emit(state.copyWith(errorMessage: 'We could not close this chat.'));
      }
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(errorMessage: 'We could not close this chat.'));
      }
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

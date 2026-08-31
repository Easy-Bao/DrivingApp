import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/chat/presentation/bloc/chat/chat_state.dart';
import 'package:shared_core/shared_core.dart';

export 'package:passenger_app/src/features/chat/presentation/bloc/chat/chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  static const _peerTypingTimeout = Duration(seconds: 3);

  final IChatRepository _chatRepository;
  StreamSubscription? _chatSubscription;
  StreamSubscription<ChatConnectionState>? _connectionStateSubscription;
  Timer? _peerTypingTimer;
  String? _roomId;
  bool _everConnected = false;
  bool _historyRequested = false;

  ChatCubit({required IChatRepository chatRepository})
    : _chatRepository = chatRepository,
      super(const ChatState());

  Future<bool> initializeChatRoom({required String roomId}) async {
    final result = await _chatRepository.initializeChatRoom(roomId: roomId);
    return result.fold((failure) {
      if (!isClosed) {
        if (failure is ChatRoomLockedFailure) {
          emit(
            state.copyWith(
              isConnecting: false,
              isConnected: false,
              isRoomLocked: true,
              lockReasonMessage: ErrorHandler.getErrorMessage(failure),
              errorMessage: null,
            ),
          );
        } else {
          emit(
            state.copyWith(
              isConnecting: false,
              errorMessage: ErrorHandler.getErrorMessage(failure),
            ),
          );
        }
      }
      return false;
    }, (_) => true);
  }

  Future<void> connectToChatRoom({
    required String roomId,
    required Uri wsUri,
    String? token,
  }) async {
    if (isClosed) return;
    _roomId = roomId;
    _historyRequested = false;
    await _connectionStateSubscription?.cancel();
    _connectionStateSubscription = _chatRepository.connectionStateStream.listen(
      _handleConnectionState,
    );
    await _chatSubscription?.cancel();
    _chatSubscription = null;
    _ensureChatSubscription();
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
          emit(state.copyWith(isConnecting: false, isConnected: true));
          _requestHistory(roomId);
        },
      );
    } catch (error, stackTrace) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isConnecting: false,
          isConnected: false,
          errorMessage: ErrorHandler.getErrorMessage(error, stackTrace),
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
      (messages) => emit(
        state.copyWith(
          messages: _mergeMessages(state.messages, messages),
          errorMessage: null,
        ),
      ),
    );
  }

  void _requestHistory(String roomId) {
    if (_historyRequested) return;
    _historyRequested = true;
    unawaited(_loadHistory(roomId));
  }

  void _ensureChatSubscription() {
    if (_chatSubscription != null) return;
    _chatSubscription = _chatRepository.chatEventsStream.listen(
      (eitherEvent) {
        if (isClosed) return;
        eitherEvent.fold(
          (failure) => emit(
            state.copyWith(errorMessage: ErrorHandler.getErrorMessage(failure)),
          ),
          (chatEvent) {
            if (chatEvent is ChatHistoryReceived) {
              emit(
                state.copyWith(
                  messages: _mergeMessages(state.messages, chatEvent.messages),
                  isPeerTyping: false,
                ),
              );
            } else if (chatEvent is ChatMessageReceived) {
              _peerTypingTimer?.cancel();
              emit(
                state.copyWith(
                  messages: _mergeMessages(state.messages, [chatEvent.message]),
                  isPeerTyping: false,
                  lastDeliveredMessage: chatEvent.message,
                ),
              );
            } else if (chatEvent is ChatTypingChanged && chatEvent.isFromPeer) {
              _updatePeerTyping(chatEvent.isTyping);
            } else if (chatEvent is ChatRoomLocked) {
              _peerTypingTimer?.cancel();
              emit(
                state.copyWith(
                  isRoomLocked: true,
                  isPeerTyping: false,
                  lockReasonMessage: ErrorHandler.getErrorMessage(
                    const ChatRoomLockedFailure(),
                  ),
                ),
              );
            }
          },
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        if (isClosed) return;
        emit(
          state.copyWith(
            errorMessage: ErrorHandler.getErrorMessage(error, stackTrace),
          ),
        );
      },
    );
  }

  Future<bool> sendMessage(String text) async {
    if (state.isRoomLocked || text.trim().isEmpty) return false;

    if (!_chatRepository.isSessionConnected) return false;
    final result = await _chatRepository.sendChatMessage(text);
    return result.fold((failure) {
      if (!isClosed) {
        emit(
          state.copyWith(errorMessage: ErrorHandler.getErrorMessage(failure)),
        );
      }
      return false;
    }, (_) => true);
  }

  Future<void> updateTypingStatus(bool isTyping) async {
    if (isClosed || state.isRoomLocked) return;
    await _chatRepository.sendTypingStatus(isTyping);
  }

  void _updatePeerTyping(bool isTyping) {
    _peerTypingTimer?.cancel();
    if (isClosed) return;

    emit(state.copyWith(isPeerTyping: isTyping));
    if (isTyping) {
      _peerTypingTimer = Timer(_peerTypingTimeout, () {
        if (!isClosed) {
          emit(state.copyWith(isPeerTyping: false));
        }
      });
    }
  }

  void _handleConnectionState(ChatConnectionState connectionState) {
    if (isClosed) return;

    switch (connectionState) {
      case ChatConnecting():
        emit(state.copyWith(isConnecting: true, isConnected: false));
      case ChatConnected():
        _everConnected = true;
        emit(
          state.copyWith(
            isConnecting: false,
            isConnected: true,
            errorMessage: null,
          ),
        );
        final roomId = _roomId;
        if (roomId != null) _requestHistory(roomId);
      case ChatDisconnected():
        _historyRequested = false;
        emit(
          state.copyWith(
            isConnecting: false,
            isConnected: false,
            errorMessage: _everConnected
                ? 'Connection lost. Reconnecting automatically...'
                : state.errorMessage,
          ),
        );
    }
  }

  List<ChatMessage> _mergeMessages(
    List<ChatMessage> current,
    List<ChatMessage> incoming,
  ) {
    final messagesByKey = <String, ChatMessage>{};
    for (final message in [...current, ...incoming]) {
      messagesByKey[_messageKey(message)] = message;
    }
    final messages = messagesByKey.values.toList();
    messages.sort((left, right) => left.createdAt.compareTo(right.createdAt));
    return messages;
  }

  String _messageKey(ChatMessage message) {
    return message.identityKey;
  }

  Future<void> resolveChatRoom(String roomId) async {
    try {
      final result = await _chatRepository.resolveChatRoom(roomId);
      await result.fold(
        (failure) async => emit(
          state.copyWith(errorMessage: ErrorHandler.getErrorMessage(failure)),
        ),
        (_) async {
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
        },
      );
    } catch (error, stackTrace) {
      if (!isClosed) {
        emit(
          state.copyWith(
            errorMessage: ErrorHandler.getErrorMessage(error, stackTrace),
          ),
        );
      }
    }
  }

  @override
  Future<void> close() async {
    _peerTypingTimer?.cancel();
    await _chatSubscription?.cancel();
    await _connectionStateSubscription?.cancel();
    await _chatRepository.terminateChatConnection();
    await _chatRepository.dispose();
    return super.close();
  }
}

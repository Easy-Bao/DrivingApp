import 'package:driver/src/features/chat/chat.dart';

import 'dart:async';

import 'package:driver/src/features/chat/presentation/bloc/chat/chat_state.dart';
import 'package:foundation/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'package:driver/src/features/chat/presentation/bloc/chat/chat_state.dart';

class ChatCubit({required this._chatRepository, this.currentUserId})
    extends Cubit<ChatState> {
  static const _peerTypingTimeout = Duration(seconds: 3);

  final ChatRepository _chatRepository;
  final String? currentUserId;
  StreamSubscription? _chatSubscription;
  StreamSubscription<ChatConnectionState>? _connectionStateSubscription;
  Timer? _peerTypingTimer;
  String? _roomId;
  bool _everConnected = false;
  bool _historyRequested = false;

  this : super(const ChatState());

  Future<bool> initializeChatRoom({required String roomId}) async {
    final result = await _chatRepository.initializeChatRoomResult(
      roomId: roomId,
    );
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
      final connResult = await _chatRepository.establishChatConnectionResult(
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
    final result = await _chatRepository.fetchRoomMessagesResult(roomId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(errorMessage: ErrorHandler.getErrorMessage(failure)),
      ),
      (messages) => emit(
        state.copyWith(
          messages: _mergeIncomingMessages(state.messages, messages),
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
    _chatSubscription = _chatRepository.chatEventsResultStream.listen(
      (eventResult) {
        if (isClosed) return;
        eventResult.fold(
          (failure) => emit(
            state.copyWith(errorMessage: ErrorHandler.getErrorMessage(failure)),
          ),
          (chatEvent) {
            if (chatEvent is ChatHistoryReceived) {
              emit(
                state.copyWith(
                  messages: _mergeIncomingMessages(
                    state.messages,
                    chatEvent.messages,
                  ),
                  isPeerTyping: false,
                ),
              );
            } else if (chatEvent is ChatMessageReceived) {
              _peerTypingTimer?.cancel();
              emit(
                state.copyWith(
                  messages: _mergeMessages(
                    _removePendingEcho(state.messages, chatEvent.message),
                    [chatEvent.message],
                  ),
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

    final trimmed = text.trim();
    final pendingMessage = ChatMessage(
      id: 'pending:${DateTime.now().microsecondsSinceEpoch}',
      text: trimmed,
      senderId: currentUserId ?? '',
      isFromPeer: false,
      createdAt: DateTime.now(),
      deliveryStatus: ChatMessageDeliveryStatus.sending,
    );
    emit(
      state.copyWith(
        messages: _mergeMessages(state.messages, [pendingMessage]),
      ),
    );
    final result = await _chatRepository.sendChatMessageResult(text);
    return result.fold((failure) {
      if (!isClosed) {
        emit(
          state.copyWith(errorMessage: ErrorHandler.getErrorMessage(failure)),
        );
        _replacePendingMessage(
          pendingMessage,
          pendingMessage.copyWith(
            deliveryStatus: ChatMessageDeliveryStatus.failed,
          ),
        );
      }
      return false;
    }, (_) => true);
  }

  Future<void> updateTypingStatus(bool isTyping) async {
    if (isClosed || state.isRoomLocked) return;
    final result = await _chatRepository.sendTypingStatusResult(isTyping);
    result.fold((failure) {
      if (!isClosed) {
        emit(
          state.copyWith(errorMessage: ErrorHandler.getErrorMessage(failure)),
        );
      }
    }, (_) {});
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

  List<ChatMessage> _removePendingEcho(
    List<ChatMessage> current,
    ChatMessage delivered,
  ) {
    if (delivered.isFromPeer) return current;
    final index = current.indexWhere(
      (message) =>
          !message.isFromPeer &&
          message.deliveryStatus != ChatMessageDeliveryStatus.delivered &&
          message.text == delivered.text,
    );
    if (index < 0) return current;
    return [...current]..removeAt(index);
  }

  List<ChatMessage> _removePendingEchoes(
    List<ChatMessage> current,
    Iterable<ChatMessage> incoming,
  ) {
    var result = current;
    for (final message in incoming) {
      result = _removePendingEcho(result, message);
    }
    return result;
  }

  List<ChatMessage> _mergeIncomingMessages(
    List<ChatMessage> current,
    List<ChatMessage> incoming,
  ) {
    return _mergeMessages(_removePendingEchoes(current, incoming), incoming);
  }

  void _replacePendingMessage(ChatMessage previous, ChatMessage replacement) {
    if (isClosed) return;
    final messages = [...state.messages];
    final index = messages.indexWhere((message) => message.id == previous.id);
    if (index < 0) return;
    messages[index] = replacement;
    emit(state.copyWith(messages: _mergeMessages(const [], messages)));
  }

  String _messageKey(ChatMessage message) {
    return message.identityKey;
  }

  Future<void> resolveChatRoom(String roomId) async {
    try {
      final result = await _chatRepository.resolveChatRoomResult(roomId);
      await result.fold(
        (failure) async => emit(
          state.copyWith(errorMessage: ErrorHandler.getErrorMessage(failure)),
        ),
        (_) async {
          await _chatSubscription?.cancel();
          await _chatRepository.terminateChatConnectionResult();
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
    await _chatRepository.terminateChatConnectionResult();
    await _chatRepository.dispose();
    return super.close();
  }
}

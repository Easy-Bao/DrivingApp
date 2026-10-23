import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/chat/chat.dart';
import 'package:passenger/src/features/chat/presentation/bloc/chat_state.dart';

export 'package:passenger/src/features/chat/presentation/bloc/chat_state.dart';

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
  String? _lastReadId;
  bool _markingRead = false;
  DateTime? _peerReadThrough;

  this : super(const ChatState());

  Future<bool> initializeChatRoom({required String roomId}) async {
    _roomId = roomId;
    unawaited(_loadPeer(roomId));
    final result = await _chatRepository.initializeChatRoomResult(
      roomId: roomId,
    );
    if (isClosed) return false;
    final initialized = result.fold((failure) {
      _handleChatFailure(failure);
      return false;
    }, (_) => true);
    if (!initialized && state.isRoomLocked) {
      await _loadHistory(roomId);
    }
    return initialized;
  }

  Future<void> _loadPeer(String roomId) async {
    final result = await _chatRepository.fetchPeer(roomId);
    if (isClosed) return;
    result.fold((_) {}, (peer) => emit(state.copyWith(peer: peer)));
  }

  Future<void> connectToChatRoom({
    required String roomId,
    Uri? chatUri,
    Uri? wsUri,
    String? token,
  }) async {
    final effectiveUri = chatUri ?? wsUri;
    if (effectiveUri == null) {
      throw ArgumentError('chatUri or wsUri must be provided.');
    }
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
      final connectionResult = await _chatRepository
          .establishChatConnectionResult(
            roomId: roomId,
            chatUri: effectiveUri,
            token: token,
          );

      if (isClosed) return;
      connectionResult.fold(_handleChatFailure, (_) {
        emit(state.copyWith(isConnecting: false, isConnected: true));
        _requestHistory(roomId);
      });
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
    if (isClosed) return;
    emit(state.copyWith(isLoadingHistory: true));
    final result = await _chatRepository.fetchRoomMessagesResult(roomId);
    if (isClosed) return;
    emit(state.copyWith(isLoadingHistory: false));
    result.fold(
      _handleChatFailure,
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
            } else if (chatEvent is ChatMessagesRead &&
                chatEvent.senderId != currentUserId) {
              if (_peerReadThrough == null ||
                  chatEvent.through.isAfter(_peerReadThrough!)) {
                _peerReadThrough = chatEvent.through;
              }
              emit(
                state.copyWith(
                  messages: _mergeMessages(state.messages, const []),
                ),
              );
            } else if (chatEvent is ChatTypingChanged && chatEvent.isFromPeer) {
              _updatePeerTyping(chatEvent.isTyping);
            } else if (chatEvent is ChatRoomLocked) {
              _peerTypingTimer?.cancel();
              _handleChatFailure(const ChatRoomLockedFailure());
              unawaited(_chatRepository.terminateChatConnectionResult());
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
    if (!state.isConnected || state.isRoomLocked || text.trim().isEmpty) {
      return false;
    }

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

  Future<void> sendImage(Uint8List bytes) async {
    final roomId = _roomId;
    if (roomId == null ||
        !state.isConnected ||
        state.isRoomLocked ||
        state.isSendingImage) {
      return;
    }
    emit(state.copyWith(isSendingImage: true, errorMessage: null));
    final result = await _chatRepository.sendImage(roomId, bytes);
    if (isClosed) return;
    result.fold(
      (failure) {
        emit(state.copyWith(isSendingImage: false));
        _handleChatFailure(failure);
      },
      (message) => emit(
        state.copyWith(
          isSendingImage: false,
          messages: _mergeMessages(state.messages, [message]),
        ),
      ),
    );
  }

  Future<Uint8List> loadImage(String messageId) async {
    final roomId = _roomId;
    if (roomId == null) throw StateError('Conversation unavailable');
    final result = await _chatRepository.fetchImage(roomId, messageId);
    return result.fold(
      (failure) => throw StateError(ErrorHandler.getErrorMessage(failure)),
      (bytes) => bytes,
    );
  }

  Future<void> markVisibleMessagesRead() async {
    final roomId = _roomId;
    if (roomId == null || isClosed || _markingRead) return;
    final peerMessages = state.messages.where(
      (message) => message.isFromPeer && message.id.isNotEmpty,
    );
    if (peerMessages.isEmpty) return;
    final id = peerMessages.last.id;
    if (id == _lastReadId) return;
    _markingRead = true;
    try {
      final result = await _chatRepository.markRead(roomId, id);
      result.fold((_) {}, (_) => _lastReadId = id);
    } finally {
      _markingRead = false;
    }
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
            errorMessage: state.isRoomLocked
                ? null
                : _everConnected
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
      final key = _messageKey(message);
      final previous = messagesByKey[key];
      final seen =
          !message.isFromPeer &&
          ((previous?.deliveryStatus == ChatMessageDeliveryStatus.seen) ||
              (_peerReadThrough != null &&
                  !message.createdAt.isAfter(_peerReadThrough!)));
      messagesByKey[key] = seen
          ? message.copyWith(deliveryStatus: ChatMessageDeliveryStatus.seen)
          : message;
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
          (message.deliveryStatus == ChatMessageDeliveryStatus.sending ||
              message.deliveryStatus == ChatMessageDeliveryStatus.failed) &&
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

  void _handleChatFailure(Failure failure) {
    if (isClosed) return;
    final message = ErrorHandler.getErrorMessage(failure);
    if (failure is ChatRoomLockedFailure) {
      emit(
        state.copyWith(
          isConnecting: false,
          isConnected: false,
          isRoomLocked: true,
          messages: state.messages
              .map(
                (item) =>
                    item.deliveryStatus == ChatMessageDeliveryStatus.sending
                    ? item.copyWith(
                        deliveryStatus: ChatMessageDeliveryStatus.failed,
                      )
                    : item,
              )
              .toList(),
          isPeerTyping: false,
          lockReasonMessage: message,
          errorMessage: null,
        ),
      );
      return;
    }
    emit(state.copyWith(isConnecting: false, errorMessage: message));
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

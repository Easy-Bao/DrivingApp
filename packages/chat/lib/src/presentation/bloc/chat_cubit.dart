import 'dart:async';
import 'dart:typed_data';

import 'package:chat/src/domain/entities/chat_connection_state.dart';
import 'package:chat/src/domain/entities/chat_event.dart';
import 'package:chat/src/domain/entities/chat_message.dart';
import 'package:chat/src/domain/failures/chat_failure.dart';
import 'package:chat/src/domain/repositories/chat_repository.dart';
import 'package:chat/src/presentation/bloc/chat_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';

class ChatCubit({required this._chatRepository, this.currentUserId})
    extends Cubit<ChatState> {
  static const _peerTypingTimeout = Duration(seconds: 3);

  final ChatRepository _chatRepository;
  final String? currentUserId;
  StreamSubscription<Result<ChatEvent, DomainFailure>>? _chatSubscription;
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
    final initialized = switch (result) {
      Ok() => true,
      Err(:final failure) => () {
        _handleChatFailure(failure);
        return false;
      }(),
    };
    if (!initialized && state.isRoomLocked) {
      await _loadHistory(roomId);
    }
    return initialized;
  }

  Future<void> _loadPeer(String roomId) async {
    final result = await _chatRepository.fetchPeer(roomId);
    if (isClosed) return;
    if (result case Ok(:final value)) {
      emit(state.copyWith(peer: value));
    }
  }

  Future<Result<String, Failure>> resolveCallPhone() async {
    final roomId = _roomId;
    if (roomId == null || isClosed) {
      return const Err(ValidationFailure('Trip contact is unavailable.'));
    }
    // Refresh permission at the moment of calling; a visible chat can outlive
    // the server's contact window.
    final result = await _chatRepository.fetchPeer(roomId);
    if (isClosed) {
      return const Err(ValidationFailure('Trip contact is unavailable.'));
    }
    return switch (result) {
      Err(:final failure) => Err(failure),
      Ok(:final value) => () {
        emit(state.copyWith(peer: value));
        return value.canCall
            ? Ok<String, Failure>(value.phone.trim())
            : const Err<String, Failure>(
                ValidationFailure(
                  'Calling is no longer available for this trip.',
                ),
              );
      }(),
    };
  }

  Future<void> connectToChatRoom({
    required String roomId,
    required Uri chatUri,
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
    emit(
      state.copyWith(
        isConnecting: true,
        errorMessage: null,
        isAccessDenied: false,
      ),
    );

    try {
      final connectionResult = await _chatRepository
          .establishChatConnectionResult(
            roomId: roomId,
            chatUri: chatUri,
            token: token,
          );

      if (isClosed) return;
      switch (connectionResult) {
        case Err(:final failure):
          _handleChatFailure(failure);
        case Ok():
          emit(state.copyWith(isConnecting: false, isConnected: true));
          _requestHistory(roomId);
      }
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
    switch (result) {
      case Err(:final failure):
        _handleChatFailure(failure);
      case Ok(:final value):
        emit(
          state.copyWith(
            messages: _mergeIncomingMessages(state.messages, value),
            errorMessage: null,
            isAccessDenied: false,
          ),
        );
    }
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
        switch (eventResult) {
          case Err(:final failure):
            emit(
              state.copyWith(
                errorMessage: ErrorHandler.getErrorMessage(failure),
              ),
            );
          case Ok(:final value):
            _handleChatEvent(value);
        }
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

  void _handleChatEvent(ChatEvent chatEvent) {
    switch (chatEvent) {
      case ChatHistoryReceived(:final messages):
        emit(
          state.copyWith(
            messages: _mergeIncomingMessages(state.messages, messages),
            isPeerTyping: false,
          ),
        );
      case ChatMessageReceived(:final message):
        _peerTypingTimer?.cancel();
        emit(
          state.copyWith(
            messages: _mergeMessages(
              _removePendingEcho(state.messages, message),
              [message],
            ),
            isPeerTyping: false,
            errorMessage: null,
            lastDeliveredMessage: message,
          ),
        );
      case ChatMessagesRead(:final senderId, :final through):
        if (senderId == currentUserId) return;
        final currentReadThrough = _peerReadThrough;
        if (currentReadThrough == null || through.isAfter(currentReadThrough)) {
          _peerReadThrough = through;
        }
        emit(
          state.copyWith(messages: _mergeMessages(state.messages, const [])),
        );
      case ChatTypingChanged(:final isTyping, :final isFromPeer):
        if (isFromPeer) _updatePeerTyping(isTyping);
      case ChatRoomLocked():
        _peerTypingTimer?.cancel();
        _handleChatFailure(const ChatRoomLockedFailure());
        unawaited(_chatRepository.terminateChatConnectionResult());
    }
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
        errorMessage: null,
      ),
    );
    return _dispatchPendingMessage(pendingMessage, text);
  }

  Future<bool> retryMessage(ChatMessage failedMessage) async {
    if (!state.isConnected ||
        state.isRoomLocked ||
        failedMessage.isFromPeer ||
        failedMessage.deliveryStatus != ChatMessageDeliveryStatus.failed ||
        failedMessage.text.trim().isEmpty) {
      return false;
    }

    final retrying = failedMessage.copyWith(
      deliveryStatus: ChatMessageDeliveryStatus.sending,
    );
    _replacePendingMessage(failedMessage, retrying, clearError: true);
    return _dispatchPendingMessage(retrying, retrying.text);
  }

  Future<bool> _dispatchPendingMessage(
    ChatMessage pendingMessage,
    String rawText,
  ) async {
    final result = await _chatRepository.sendChatMessageResult(rawText);
    return switch (result) {
      Ok() => true,
      Err(:final failure) => () {
        if (!isClosed) {
          if (failure is ChatRoomLockedFailure) {
            _handleChatFailure(failure);
          } else {
            _replacePendingMessage(
              pendingMessage,
              pendingMessage.copyWith(
                deliveryStatus: ChatMessageDeliveryStatus.failed,
              ),
            );
          }
        }
        return false;
      }(),
    };
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
    switch (result) {
      case Err(:final failure):
        emit(state.copyWith(isSendingImage: false));
        _handleChatFailure(failure);
      case Ok(:final value):
        emit(
          state.copyWith(
            isSendingImage: false,
            messages: _mergeMessages(state.messages, [value]),
            lastDeliveredMessage: value,
          ),
        );
    }
  }

  Future<Uint8List> loadImage(String messageId) async {
    final roomId = _roomId;
    if (roomId == null) throw StateError('Conversation unavailable');
    final result = await _chatRepository.fetchImage(roomId, messageId);
    return switch (result) {
      Err(:final failure) => throw StateError(
        ErrorHandler.getErrorMessage(failure),
      ),
      Ok(:final value) => value,
    };
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
      if (result.isOk) _lastReadId = id;
    } finally {
      _markingRead = false;
    }
  }

  Future<void> updateTypingStatus(bool isTyping) async {
    if (isClosed || state.isRoomLocked) return;
    final result = await _chatRepository.sendTypingStatusResult(isTyping);
    if (result case Err(:final failure) when !isClosed) {
      emit(state.copyWith(errorMessage: ErrorHandler.getErrorMessage(failure)));
    }
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
            isAccessDenied: false,
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
    final peerReadThrough = _peerReadThrough;
    for (final message in [...current, ...incoming]) {
      final key = message.identityKey;
      final previous = messagesByKey[key];
      final seen =
          !message.isFromPeer &&
          ((previous?.deliveryStatus == ChatMessageDeliveryStatus.seen) ||
              (peerReadThrough != null &&
                  !message.createdAt.isAfter(peerReadThrough)));
      messagesByKey[key] = seen
          ? message.copyWith(deliveryStatus: ChatMessageDeliveryStatus.seen)
          : message;
    }
    final messages = messagesByKey.values.toList()
      ..sort((left, right) => left.createdAt.compareTo(right.createdAt));
    return List<ChatMessage>.unmodifiable(messages);
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

  void _replacePendingMessage(
    ChatMessage previous,
    ChatMessage replacement, {
    bool clearError = false,
  }) {
    if (isClosed) return;
    final messages = [...state.messages];
    final index = messages.indexWhere((message) => message.id == previous.id);
    if (index < 0) return;
    messages[index] = replacement;
    emit(
      state.copyWith(
        messages: _mergeMessages(const [], messages),
        errorMessage: clearError ? null : state.errorMessage,
      ),
    );
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
              .toList(growable: false),
          isPeerTyping: false,
          lockReasonMessage: message,
          errorMessage: null,
          isAccessDenied: false,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        isConnecting: false,
        errorMessage: message,
        isAccessDenied: failure is ServerFailure && failure.statusCode == 403,
      ),
    );
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

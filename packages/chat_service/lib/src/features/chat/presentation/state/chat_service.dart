import 'dart:async';
import 'package:chat_service/src/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:chat_service/src/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:chat_service/src/features/chat/domain/entities/chat_event.dart';
import 'package:chat_service/src/features/chat/domain/entities/chat_message.dart';
import 'package:chat_service/src/features/chat/domain/repositories/chat_repository.dart';
import 'package:dio/dio.dart';

class ChatService {
  final ChatRepository _chatRepository;
  final List<ChatMessage> _chatHistoryMessages = [];
  bool _isRoomLocked = false;
  String _lockReasonMessage = '';

  final StreamController<void> _chatUpdateStreamController =
      StreamController<void>.broadcast();
  StreamSubscription? _chatEventsSubscription;

  /// Creates a [ChatService] facade with feature-specific implementations.
  ChatService({required String currentUserId, Dio? dio})
      : _chatRepository = ChatRepositoryImpl(
          remoteDataSource: WebSocketChatRemoteDataSource(),
          currentUserId: currentUserId,
          dio: dio,
        );

  /// The active historical log of messages retrieved for the connected room.
  List<ChatMessage> get chatHistoryMessages => _chatHistoryMessages;

  /// Returns whether the service connection session is currently active.
  bool get isConnectionActive => _chatRepository.isSessionConnected;

  /// Returns whether the active room session has been locked.
  bool get isRoomLocked => _isRoomLocked;

  /// The warning description indicating why the room is locked.
  String get lockReasonMessage => _lockReasonMessage;

  /// Broadcast stream signaling when the UI should rebuild to reflect state updates.
  Stream<void> get chatUpdatesStream => _chatUpdateStreamController.stream;

  /// Connects to a chat room using WebSocket protocols.
  Future<void> connectToChatRoom({
    required String roomId,
    required Uri chatUri,
  }) async {
    if (roomId.isEmpty) {
      throw ArgumentError('Room ID cannot be empty');
    }

    _chatHistoryMessages.clear();
    _isRoomLocked = false;
    _lockReasonMessage = '';

    final connectionResult = await _chatRepository.establishChatConnection(
      roomId: roomId,
      chatUri: chatUri,
    );

    connectionResult.fold(
      (failure) {
        _chatUpdateStreamController.add(null);
        throw failure;
      },
      (_) {
        unawaited(_chatEventsSubscription?.cancel());
        _chatEventsSubscription = _chatRepository.chatEventsStream.listen(
          (eventResult) {
            eventResult.fold(
              (failure) {
                // Gracefully sink error or ignore internal parse failures
              },
              (event) {
                switch (event) {
                  case ChatHistoryReceived(:final messages):
                    _chatHistoryMessages.clear();
                    _chatHistoryMessages.addAll(messages);
                    break;
                  case ChatMessageReceived(:final message):
                    _chatHistoryMessages.add(message);
                    break;
                  case ChatRoomLocked(:final reason):
                    _isRoomLocked = true;
                    _lockReasonMessage = reason;
                    break;
                }
                _chatUpdateStreamController.add(null);
              },
            );
          },
          onError: (_) {
            _chatUpdateStreamController.add(null);
          },
          onDone: () {
            _chatUpdateStreamController.add(null);
          },
        );
        _chatUpdateStreamController.add(null);
      },
    );
  }

  void sendMessageToRoom(String text) {
    if (_isRoomLocked) return;
    unawaited(_chatRepository.sendChatMessage(text));
  }

  Future<void> disconnectChatRoom() async {
    await _chatEventsSubscription?.cancel();
    await _chatRepository.terminateChatConnection();
    unawaited(_chatUpdateStreamController.close());
  }
}

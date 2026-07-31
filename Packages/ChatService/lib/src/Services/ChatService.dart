import 'dart:async';

import 'package:chat_service/src/Models/ChatEvent.dart';
import 'package:chat_service/src/Models/ChatMessage.dart';
import 'package:chat_service/src/Repositories/ChatRepository.dart';
import 'package:chat_service/src/Repositories/ChatRepositoryImpl.dart';
import 'package:chat_service/src/Services/ChatRemoteDataSource.dart';

class ChatService {
  final ChatRepository _chatRepository;
  final List<ChatMessage> _chatHistoryMessages = [];
  bool _isRoomLocked = false;
  String _lockReasonMessage = '';

  final StreamController<void> _chatUpdateStreamController =
      StreamController<void>.broadcast();
  StreamSubscription? _chatEventsSubscription;

  ChatService({required String currentUserId})
      : _chatRepository = ChatRepositoryImpl(
          remoteDataSource: WebSocketChatRemoteDataSource(),
          currentUserId: currentUserId,
        );

  List<ChatMessage> get chatHistoryMessages => _chatHistoryMessages;
  bool get isConnectionActive => _chatRepository.isSessionConnected;
  bool get isRoomLocked => _isRoomLocked;
  String get lockReasonMessage => _lockReasonMessage;
  Stream<void> get chatUpdatesStream => _chatUpdateStreamController.stream;

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
              (failure) {},
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

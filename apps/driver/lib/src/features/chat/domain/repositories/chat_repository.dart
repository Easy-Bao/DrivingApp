import 'dart:typed_data';

import 'package:driver/src/features/chat/domain/entities/chat_peer.dart';

import 'dart:async';

import 'package:driver/src/features/chat/domain/entities/chat_connection_state.dart';
import 'package:driver/src/features/chat/domain/entities/chat_event.dart';
import 'package:driver/src/features/chat/domain/entities/chat_message.dart';
import 'package:foundation/foundation.dart';

abstract interface class ChatRepository {
  Future<Result<void, Failure>> establishChatConnection({
    required String roomId,
    required Uri chatUri,
    String? token,
  });

  Future<Result<void, Failure>> terminateChatConnection();

  Future<Result<void, Failure>> initializeChatRoom({required String roomId});

  Future<Result<void, Failure>> sendChatMessage(String text);
  Future<Result<ChatMessage, Failure>> sendImage(
    String roomId,
    Uint8List bytes,
  );
  Future<Result<Uint8List, Failure>> fetchImage(
    String roomId,
    String messageId,
  );
  Future<Result<void, Failure>> markRead(String roomId, String messageId);
  Future<Result<ChatPeer, Failure>> fetchPeer(String roomId);

  Future<Result<void, Failure>> sendTypingStatus(bool isTyping);

  Future<Result<List<ChatMessage>, Failure>> fetchRoomMessages(String roomId);

  Future<void> dispose();

  Stream<Result<ChatEvent, Failure>> get chatEventsStream;

  Stream<ChatConnectionState> get connectionStateStream;

  bool get isSessionConnected;
}

extension ChatRepositoryResultApi on ChatRepository {
  Future<Result<void, DomainFailure>> establishChatConnectionResult({
    required String roomId,
    required Uri chatUri,
    String? token,
  }) {
    return captureResult(
      () => establishChatConnection(
        roomId: roomId,
        chatUri: chatUri,
        token: token,
      ),
      message: 'Unable to connect to chat right now.',
    );
  }

  Future<Result<void, DomainFailure>> terminateChatConnectionResult() {
    return captureResult(
      terminateChatConnection,
      message: 'Unable to disconnect chat right now.',
    );
  }

  Future<Result<void, DomainFailure>> initializeChatRoomResult({
    required String roomId,
  }) {
    return captureResult(
      () => initializeChatRoom(roomId: roomId),
      message: 'Unable to initialize chat right now.',
    );
  }

  Future<Result<void, DomainFailure>> sendChatMessageResult(String text) {
    return captureResult(
      () => sendChatMessage(text),
      message: 'Unable to send chat message right now.',
    );
  }

  Future<Result<void, DomainFailure>> sendTypingStatusResult(bool isTyping) {
    return captureResult(
      () => sendTypingStatus(isTyping),
      message: 'Unable to update chat status right now.',
    );
  }

  Future<Result<List<ChatMessage>, DomainFailure>> fetchRoomMessagesResult(
    String roomId,
  ) {
    return captureResult(
      () => fetchRoomMessages(roomId),
      message: 'Unable to load chat history right now.',
    );
  }

  Stream<Result<ChatEvent, DomainFailure>> get chatEventsResultStream {
    return chatEventsStream.transform(
      StreamTransformer<
        Result<ChatEvent, Failure>,
        Result<ChatEvent, DomainFailure>
      >.fromHandlers(
        handleData: (event, sink) => sink.add(event),
        handleError: (error, stackTrace, sink) => sink.add(
          Err<ChatEvent, DomainFailure>(
            FailureMapper.fromException(
              error,
              serverMessage: 'The chat connection ended unexpectedly.',
            ),
          ),
        ),
      ),
    );
  }
}

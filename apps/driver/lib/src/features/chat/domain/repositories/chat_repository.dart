import 'dart:async';

import 'package:driver/src/features/chat/domain/entities/chat_connection_state.dart';
import 'package:driver/src/features/chat/domain/entities/chat_event.dart';
import 'package:driver/src/features/chat/domain/entities/chat_message.dart';
import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class ChatRepository {
  Future<Either<Failure, void>> establishChatConnection({
    required String roomId,
    required Uri chatUri,
    String? token,
  });

  Future<Either<Failure, void>> terminateChatConnection();

  Future<Either<Failure, void>> initializeChatRoom({required String roomId});

  Future<Either<Failure, void>> sendChatMessage(String text);

  Future<Either<Failure, void>> sendTypingStatus(bool isTyping);

  Future<Either<Failure, List<ChatMessage>>> fetchRoomMessages(String roomId);

  Future<Either<Failure, void>> resolveChatRoom(String roomId);

  Future<void> dispose();

  Stream<Either<Failure, ChatEvent>> get chatEventsStream;

  Stream<ChatConnectionState> get connectionStateStream;

  bool get isSessionConnected;
}

extension ChatRepositoryResultApi on ChatRepository {
  Future<Result<void, DomainFailure>> establishChatConnectionResult({
    required String roomId,
    required Uri chatUri,
    String? token,
  }) {
    return _captureChatResult(
      () => establishChatConnection(
        roomId: roomId,
        chatUri: chatUri,
        token: token,
      ),
      message: 'Unable to connect to chat right now.',
    );
  }

  Future<Result<void, DomainFailure>> terminateChatConnectionResult() {
    return _captureChatResult(
      terminateChatConnection,
      message: 'Unable to disconnect chat right now.',
    );
  }

  Future<Result<void, DomainFailure>> initializeChatRoomResult({
    required String roomId,
  }) {
    return _captureChatResult(
      () => initializeChatRoom(roomId: roomId),
      message: 'Unable to initialize chat right now.',
    );
  }

  Future<Result<void, DomainFailure>> sendChatMessageResult(String text) {
    return _captureChatResult(
      () => sendChatMessage(text),
      message: 'Unable to send chat message right now.',
    );
  }

  Future<Result<void, DomainFailure>> sendTypingStatusResult(bool isTyping) {
    return _captureChatResult(
      () => sendTypingStatus(isTyping),
      message: 'Unable to update chat status right now.',
    );
  }

  Future<Result<List<ChatMessage>, DomainFailure>> fetchRoomMessagesResult(
    String roomId,
  ) {
    return _captureChatResult(
      () => fetchRoomMessages(roomId),
      message: 'Unable to load chat history right now.',
    );
  }

  Future<Result<void, DomainFailure>> resolveChatRoomResult(String roomId) {
    return _captureChatResult(
      () => resolveChatRoom(roomId),
      message: 'Unable to resolve chat room right now.',
    );
  }

  Stream<Result<ChatEvent, DomainFailure>> get chatEventsResultStream {
    return chatEventsStream.transform(
      StreamTransformer<
        Either<Failure, ChatEvent>,
        Result<ChatEvent, DomainFailure>
      >.fromHandlers(
        handleData: (event, sink) => sink.add(_toChatResult(event)),
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

Future<Result<T, DomainFailure>> _captureChatResult<T>(
  Future<Either<Failure, T>> Function() operation, {
  required String message,
}) async {
  try {
    return _toChatResult(await operation());
  } catch (error) {
    return Err<T, DomainFailure>(
      FailureMapper.fromException(error, serverMessage: message),
    );
  }
}

Result<T, DomainFailure> _toChatResult<T>(Either<Failure, T> result) {
  return result.fold<Result<T, DomainFailure>>(
    (failure) => Err<T, DomainFailure>(failure),
    (value) => Ok<T, DomainFailure>(value),
  );
}

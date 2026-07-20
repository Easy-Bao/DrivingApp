import 'dart:async';
import 'dart:convert';
import 'package:chat_service/src/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:chat_service/src/features/chat/data/models/chat_message_model.dart';
import 'package:chat_service/src/features/chat/domain/entities/chat_event.dart';
import 'package:chat_service/src/features/chat/domain/entities/chat_message.dart';
import 'package:chat_service/src/features/chat/domain/repositories/chat_repository.dart';
import 'package:core_models/core_models.dart';
import 'package:fpdart/fpdart.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final String currentUserId;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.currentUserId,
  });

  @override
  bool get isSessionConnected => remoteDataSource.isWebSocketConnected;

  @override
  Future<Either<Failure, void>> establishChatConnection({
    required String roomId,
    required Uri chatUri,
  }) async {
    try {
      await remoteDataSource.establishWebSocketConnection(chatUri);
      return const Right(null);
    } catch (error) {
      return Left(NetworkFailure('Failed to connect to chat server: $error'));
    }
  }

  @override
  Future<Either<Failure, void>> terminateChatConnection() async {
    try {
      await remoteDataSource.terminateWebSocketConnection();
      return const Right(null);
    } catch (error) {
      return Left(ServerFailure('Failed to disconnect from chat: $error'));
    }
  }

  @override
  Future<Either<Failure, void>> sendChatMessage(String text) async {
    try {
      final normalizedText = text.trim();
      if (normalizedText.isEmpty) {
        return const Left(ValidationFailure('Message text cannot be empty.'));
      }
      final payload = jsonEncode({'text': normalizedText});
      remoteDataSource.sendWebSocketChatMessage(payload);
      return const Right(null);
    } catch (error) {
      return Left(NetworkFailure('Failed to send message: $error'));
    }
  }

  @override
  Stream<Either<Failure, ChatEvent>> get chatEventsStream {
    return remoteDataSource.webSocketEventStream.transform(
      StreamTransformer<String, Either<Failure, ChatEvent>>.fromHandlers(
        handleData: (data, sink) {
          try {
            final jsonMap = jsonDecode(data) as Map<String, dynamic>;
            final eventType = jsonMap['type'] as String?;

            if (eventType == 'history') {
              final messagesRaw = jsonMap['messages'] as List?;
              final List<ChatMessage> messageList = [];
              if (messagesRaw != null) {
                for (final item in messagesRaw) {
                  if (item is Map<String, dynamic>) {
                    final model = ChatMessageModel.fromJson(item);
                    messageList.add(
                      model.toEntity(currentUserId: currentUserId),
                    );
                  }
                }
              }
              sink.add(Right(ChatHistoryReceived(messageList)));
            } else if (eventType == 'message') {
              final model = ChatMessageModel.fromJson(jsonMap);
              final entity = model.toEntity(currentUserId: currentUserId);
              sink.add(Right(ChatMessageReceived(entity)));
            } else if (eventType == 'locked') {
              final reason = jsonMap['reason'] as String? ??
                  'This conversation is locked.';
              sink.add(Right(ChatRoomLocked(reason)));
            } else {
              sink.add(
                Left(ValidationFailure('Unknown event type: $eventType')),
              );
            }
          } catch (error) {
            sink.add(
              Left(ValidationFailure('Failed to parse chat event: $error')),
            );
          }
        },
        handleError: (error, stack, sink) {
          sink.add(Left(NetworkFailure('WebSocket error: $error')));
        },
      ),
    );
  }
}

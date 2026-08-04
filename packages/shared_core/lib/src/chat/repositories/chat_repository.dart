import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_core/shared_core.dart';

class ChatRepository implements IChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final String currentUserId;
  final Dio clientDio;

  ChatRepository({
    required this.remoteDataSource,
    required this.currentUserId,
    required this.clientDio,
  });

  @override
  bool get isSessionConnected => remoteDataSource.isWebSocketConnected;

  @override
  Future<Either<Failure, void>> establishChatConnection({
    required String roomId,
    required Uri chatUri,
    String? token,
  }) async {
    try {
      await remoteDataSource.establishWebSocketConnection(
        chatUri,
        token: token,
      );
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
      return Left(NetworkFailure('Failed to disconnect chat session: $error'));
    }
  }

  @override
  Future<Either<Failure, void>> sendChatMessage(String text) async {
    if (!isSessionConnected) {
      return const Left(NetworkFailure('Chat session is disconnected.'));
    }

    try {
      final payload = jsonEncode({
        'type': 'message',
        'text': text.trim(),
        'senderId': currentUserId,
        'createdAt': DateTime.now().toIso8601String(),
      });

      remoteDataSource.sendWebSocketChatMessage(payload);
      return const Right(null);
    } catch (error) {
      return Left(ServerFailure('Failed to send chat payload: $error'));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> fetchRoomMessages(
    String roomId,
  ) async {
    try {
      final response = await clientDio.get('/chat/rooms/$roomId/messages');

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final Map<String, dynamic> dataMap =
            response.data as Map<String, dynamic>;
        final List<dynamic> list =
            (dataMap['messages'] ?? dataMap['data'] ?? []) as List<dynamic>;

        final messages = list.map((item) {
          final model = ChatMessageModel.fromJson(item as Map<String, dynamic>);
          return model.toEntity(currentUserId: currentUserId);
        }).toList();

        return Right(messages);
      }
      return const Right([]);
    } catch (error) {
      return Left(
        ServerFailure('Failed to fetch historical chat room logs: $error'),
      );
    }
  }

  @override
  Stream<Either<Failure, ChatEvent>> get chatEventsStream {
    return remoteDataSource.webSocketEventStream.map((rawString) {
      try {
        final decoded = jsonDecode(rawString) as Map<String, dynamic>;
        final type = decoded['type'] as String?;

        if (type == 'history' && decoded['messages'] is List) {
          final list = decoded['messages'] as List;
          final messages = list.map((item) {
            final model = ChatMessageModel.fromJson(
              item as Map<String, dynamic>,
            );
            return model.toEntity(currentUserId: currentUserId);
          }).toList();
          return Right(ChatHistoryReceived(messages));
        }

        if (type == 'message') {
          final model = ChatMessageModel.fromJson(decoded);
          return Right(
            ChatMessageReceived(model.toEntity(currentUserId: currentUserId)),
          );
        }

        if (type == 'room_locked' || type == 'locked') {
          final reason = decoded['reason'] as String? ?? 'Trip completed';
          return Right(ChatRoomLocked(reason));
        }

        return Left(ServerFailure('Unknown websocket chat event type: $type'));
      } catch (error) {
        return Left(
          ServerFailure('Failed to parse incoming websocket payload: $error'),
        );
      }
    });
  }
}

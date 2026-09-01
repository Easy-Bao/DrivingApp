import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger/src/features/chat/data/data_sources/chat_remote_data_source.dart';
import 'package:passenger/src/features/chat/data/dto/chat_message_dto.dart';
import 'package:passenger/src/features/chat/domain/entities/chat_connection_state.dart';
import 'package:passenger/src/features/chat/domain/entities/chat_event.dart';
import 'package:passenger/src/features/chat/domain/entities/chat_message.dart';
import 'package:passenger/src/features/chat/domain/failures/chat_failure.dart';
import 'package:passenger/src/features/chat/domain/repositories/chat_repository.dart';

final class ChatRepositoryImpl({
  required this.remoteDataSource,
  required this.currentUserId,
  required this.clientDio,
  this.tokenProvider,
}) implements ChatRepository {
  static const _maxMessageBytes = 4096;
  final ChatRemoteDataSource remoteDataSource;
  final String currentUserId;
  final Dio clientDio;
  final Future<String?> Function()? tokenProvider;

  @override
  bool get isSessionConnected => remoteDataSource.isWebSocketConnected;

  @override
  Stream<ChatConnectionState> get connectionStateStream =>
      remoteDataSource.connectionStateStream;

  @override
  Future<Either<Failure, void>> establishChatConnection({
    required String roomId,
    required Uri chatUri,
    String? token,
  }) async {
    try {
      final resolvedToken = token ?? await tokenProvider?.call();
      await remoteDataSource.establishWebSocketConnection(
        chatUri,
        token: resolvedToken,
      );
      return const Right(null);
    } catch (error) {
      return Left(_mapChatFailure(error, 'Unable to connect to chat server.'));
    }
  }

  @override
  Future<Either<Failure, void>> terminateChatConnection() async {
    try {
      await remoteDataSource.terminateWebSocketConnection();
      return const Right(null);
    } catch (error) {
      return const Left(NetworkFailure('Unable to disconnect chat session.'));
    }
  }

  @override
  Future<Either<Failure, void>> initializeChatRoom({
    required String roomId,
  }) async {
    final rideId = roomId.trim();
    if (rideId.isEmpty) {
      return const Left(ValidationFailure('Ride ID is required.'));
    }

    try {
      final response = await clientDio.post<void>(
        '/api/v1/chat/rooms',
        data: {'ride_id': rideId},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return const Right(null);
      }
      if (response.statusCode == 423) {
        return const Left(ChatRoomLockedFailure());
      }
      return Left(
        ServerFailure.withStatusCode(
          'Unable to initialize chat room.',
          response.statusCode ?? 500,
        ),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 423) {
        return const Left(ChatRoomLockedFailure());
      }
      return Left(_mapChatFailure(error, 'Unable to initialize chat room.'));
    } catch (error) {
      return Left(_mapChatFailure(error, 'Unable to initialize chat room.'));
    }
  }

  @override
  Future<Either<Failure, void>> sendChatMessage(String text) async {
    if (!isSessionConnected) {
      return const Left(NetworkFailure('Chat session is disconnected.'));
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const Left(ValidationFailure('Message cannot be empty.'));
    }
    if (utf8.encode(trimmed).length > _maxMessageBytes) {
      return const Left(ValidationFailure('Message is too long.'));
    }

    try {
      final payload = jsonEncode({'type': 'message', 'text': trimmed});

      remoteDataSource.sendWebSocketChatMessage(payload);
      return const Right(null);
    } catch (error) {
      return Left(_mapChatFailure(error, 'Unable to send chat message.'));
    }
  }

  @override
  Future<Either<Failure, void>> sendTypingStatus(bool isTyping) async {
    if (!isSessionConnected) {
      return const Left(NetworkFailure('Chat session is disconnected.'));
    }

    try {
      remoteDataSource.sendWebSocketTypingStatus(isTyping);
      return const Right(null);
    } catch (error) {
      return Left(_mapChatFailure(error, 'Unable to update chat status.'));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> fetchRoomMessages(
    String roomId,
  ) async {
    try {
      final response = await clientDio.get<Object?>(
        '/api/v1/chat/rooms/${Uri.encodeComponent(roomId)}/messages',
      );

      if (response.statusCode != 200) return const Right([]);
      final dataMap = decodeObjectMap(response.data);
      final rawMessages = dataMap['messages'] ?? dataMap['data'] ?? const [];
      return Right(_decodeMessages(rawMessages));
    } catch (error) {
      return Left(_mapChatFailure(error, 'Unable to load chat history.'));
    }
  }

  @override
  Future<Either<Failure, void>> resolveChatRoom(String roomId) async {
    try {
      final response = await clientDio.post<void>(
        '/api/v1/chat/rooms/${Uri.encodeComponent(roomId)}/resolve',
      );
      if (response.statusCode == 200) return const Right(null);
      return Left(
        ServerFailure.withStatusCode(
          'Unable to resolve chat room.',
          response.statusCode ?? 500,
        ),
      );
    } catch (error) {
      return Left(_mapChatFailure(error, 'Unable to resolve chat room.'));
    }
  }

  @override
  Future<void> dispose() => remoteDataSource.dispose();

  @override
  Stream<Either<Failure, ChatEvent>> get chatEventsStream {
    return remoteDataSource.webSocketEventStream.map((rawString) {
      try {
        final decoded = decodeObjectMap(jsonDecode(rawString));
        final type = decoded['type'];
        if (type is! String) {
          return const Left(ServerFailure('Unable to read chat event.'));
        }

        return switch (type) {
          'history' when decoded['messages'] is List => Right(
            ChatHistoryReceived(_decodeMessages(decoded['messages'])),
          ),
          'message' => Right(
            ChatMessageReceived(
              ChatMessageDto.fromJson(decoded)
                  .toEntity(currentUserId: currentUserId),
            ),
          ),
          'typing' => _decodeTypingEvent(decoded),
          'room_locked' || 'locked' => Right(
            ChatRoomLocked(_stringValueOr(decoded['reason'], 'Trip completed')),
          ),
          _ => const Left(ServerFailure('Unable to read chat event.')),
        };
      } catch (error) {
        return const Left(ServerFailure('Unable to read chat message.'));
      }
    });
  }

  List<ChatMessage> _decodeMessages(Object? rawMessages) {
    if (rawMessages is! List) {
      throw const FormatException('Chat messages payload is invalid.');
    }
    return rawMessages
        .map(
          (item) => ChatMessageDto.fromJson(
            decodeObjectMap(item, message: 'Chat message is invalid.'),
          ).toEntity(currentUserId: currentUserId),
        )
        .toList(growable: false);
  }

  String _stringValueOr(Object? value, String fallback) => switch (value) {
    final String text => text,
    _ => fallback,
  };

  Either<Failure, ChatEvent> _decodeTypingEvent(Map<String, dynamic> decoded) {
    final senderId = switch (decoded['sender_id']) {
      final String value => value,
      _ => switch (decoded['senderId']) {
        final String value => value,
        _ => '',
      },
    };
    final isTyping = switch (decoded['is_typing']) {
      final bool value => value,
      _ => switch (decoded['isTyping']) {
        final bool value => value,
        _ => null,
      },
    };
    if (senderId.isEmpty || isTyping == null) {
      return const Left(ServerFailure('Unable to read chat status.'));
    }
    return Right(
      ChatTypingChanged(
        isTyping: isTyping,
        isFromPeer: senderId != currentUserId,
      ),
    );
  }
}

Failure _mapChatFailure(Object error, String message) {
  return FailureMapper.fromException(
    error,
    serverMessage: message,
    networkMessage:
        'Unable to connect to chat. Check your connection and try again.',
    timeoutMessage: 'Chat request timed out. Please try again.',
  );
}

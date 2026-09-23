import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';
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
  Future<Result<void, Failure>> establishChatConnection({
    required String roomId,
    required Uri chatUri,
    String? token,
  }) async {
    try {
      final resolvedToken = tokenProvider == null
          ? token
          : await tokenProvider!.call();
      await remoteDataSource.establishWebSocketConnection(
        chatUri,
        token: resolvedToken,
      );
      return const Ok(null);
    } catch (error) {
      return Err(_mapChatFailure(error, 'Unable to connect to chat server.'));
    }
  }

  @override
  Future<Result<void, Failure>> terminateChatConnection() async {
    try {
      await remoteDataSource.terminateWebSocketConnection();
      return const Ok(null);
    } catch (error) {
      return const Err(NetworkFailure('Unable to disconnect chat session.'));
    }
  }

  @override
  Future<Result<void, Failure>> initializeChatRoom({
    required String roomId,
  }) async {
    final rideId = roomId.trim();
    if (rideId.isEmpty) {
      return const Err(ValidationFailure('Ride ID is required.'));
    }

    try {
      final response = await clientDio.post<void>(
        '/api/v1/chat/rooms',
        data: {'ride_id': rideId},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return const Ok(null);
      }
      if (response.statusCode == 423) {
        return const Err(ChatRoomLockedFailure());
      }
      return Err(
        ServerFailure.withStatusCode(
          'Unable to initialize chat room.',
          response.statusCode ?? 500,
        ),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 423) {
        return const Err(ChatRoomLockedFailure());
      }
      return Err(_mapChatFailure(error, 'Unable to initialize chat room.'));
    } catch (error) {
      return Err(_mapChatFailure(error, 'Unable to initialize chat room.'));
    }
  }

  @override
  Future<Result<void, Failure>> sendChatMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const Err(ValidationFailure('Message cannot be empty.'));
    }
    if (utf8.encode(trimmed).length > _maxMessageBytes) {
      return const Err(ValidationFailure('Message is too long.'));
    }

    try {
      final payload = jsonEncode({'type': 'message', 'text': trimmed});

      remoteDataSource.sendWebSocketChatMessage(payload);
      return const Ok(null);
    } catch (error) {
      return Err(_mapChatFailure(error, 'Unable to send chat message.'));
    }
  }

  @override
  Future<Result<void, Failure>> sendTypingStatus(bool isTyping) async {
    if (!isSessionConnected) {
      return const Err(NetworkFailure('Chat session is disconnected.'));
    }

    try {
      remoteDataSource.sendWebSocketTypingStatus(isTyping);
      return const Ok(null);
    } catch (error) {
      return Err(_mapChatFailure(error, 'Unable to update chat status.'));
    }
  }

  @override
  Future<Result<List<ChatMessage>, Failure>> fetchRoomMessages(
    String roomId,
  ) async {
    try {
      final response = await clientDio.get<Object?>(
        '/api/v1/chat/rooms/${Uri.encodeComponent(roomId)}/messages',
      );

      if (response.statusCode != 200) return const Ok([]);
      final dataMap = decodeObjectMap(response.data);
      final rawMessages = dataMap['messages'] ?? dataMap['data'] ?? const [];
      return Ok(_decodeMessages(rawMessages));
    } catch (error) {
      return Err(_mapChatFailure(error, 'Unable to load chat history.'));
    }
  }

  @override
  Future<Result<void, Failure>> resolveChatRoom(String roomId) async {
    try {
      final response = await clientDio.post<void>(
        '/api/v1/chat/rooms/${Uri.encodeComponent(roomId)}/resolve',
      );
      if (response.statusCode == 200) return const Ok(null);
      return Err(
        ServerFailure.withStatusCode(
          'Unable to resolve chat room.',
          response.statusCode ?? 500,
        ),
      );
    } catch (error) {
      return Err(_mapChatFailure(error, 'Unable to resolve chat room.'));
    }
  }

  @override
  Future<void> dispose() => remoteDataSource.dispose();

  @override
  Stream<Result<ChatEvent, Failure>> get chatEventsStream {
    return remoteDataSource.webSocketEventStream.map((rawString) {
      try {
        final decoded = decodeObjectMap(jsonDecode(rawString));
        final type = decoded['type'];
        if (type is! String) {
          return const Err(ServerFailure('Unable to read chat event.'));
        }

        return switch (type) {
          'history' when decoded['messages'] is List => Ok(
            ChatHistoryReceived(_decodeMessages(decoded['messages'])),
          ),
          'message' => Ok(
            ChatMessageReceived(
              ChatMessageDto.fromJson(decoded)
                  .toEntity(currentUserId: currentUserId),
            ),
          ),
          'typing' => _decodeTypingEvent(decoded),
          'room_locked' || 'locked' => Ok(
            ChatRoomLocked(_stringValueOr(decoded['reason'], 'Trip completed')),
          ),
          _ => const Err(ServerFailure('Unable to read chat event.')),
        };
      } catch (error) {
        return const Err(ServerFailure('Unable to read chat message.'));
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

  Result<ChatEvent, Failure> _decodeTypingEvent(Map<String, dynamic> decoded) {
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
      return const Err(ServerFailure('Unable to read chat status.'));
    }
    return Ok(
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

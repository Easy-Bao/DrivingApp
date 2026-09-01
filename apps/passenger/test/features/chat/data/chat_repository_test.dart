import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger/src/features/chat/chat.dart';

class FakeChatRemoteDataSource implements ChatRemoteDataSource {
  bool sent = false;
  String? sentPayload;
  String? typingPayload;
  String? connectionToken;
  bool disposed = false;
  Stream<String> eventStream = const Stream.empty();
  Stream<ChatConnectionState> connectionStates = const Stream.empty();

  @override
  Future<void> establishWebSocketConnection(
    Uri chatServiceUri, {
    String? token,
  }) async {
    connectionToken = token;
  }

  @override
  void sendWebSocketChatMessage(String messagePayload) {
    sent = true;
    sentPayload = messagePayload;
  }

  @override
  void sendWebSocketTypingStatus(bool isTyping) {
    typingPayload = jsonEncode({'type': 'typing', 'is_typing': isTyping});
  }

  @override
  Future<void> terminateWebSocketConnection() async {}

  @override
  Stream<String> get webSocketEventStream => eventStream;

  @override
  Stream<ChatConnectionState> get connectionStateStream => connectionStates;

  @override
  bool get isWebSocketConnected => true;

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  test('opens a chat room with only the authoritative ride id', () async {
    RequestOptions? capturedRequest;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = _StubHttpClientAdapter((options) {
        capturedRequest = options;
        return ResponseBody.fromString(
          '{}',
          201,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
    final repository = ChatRepositoryImpl(
      remoteDataSource: FakeChatRemoteDataSource(),
      currentUserId: '7',
      clientDio: dio,
    );

    final result = await repository.initializeChatRoom(roomId: '303');

    expect(result.isRight(), isTrue);
    expect(capturedRequest?.path, '/api/v1/chat/rooms');
    expect(capturedRequest?.data, {'ride_id': '303'});
  });

  test('obtains the websocket token from its composition root', () async {
    final remoteDataSource = FakeChatRemoteDataSource();
    final repository = ChatRepositoryImpl(
      remoteDataSource: remoteDataSource,
      currentUserId: '7',
      clientDio: Dio(),
      tokenProvider: () async => 'session-token',
    );

    final result = await repository.establishChatConnection(
      roomId: '303',
      chatUri: Uri.parse('ws://localhost/chat'),
    );

    expect(result.isRight(), isTrue);
    expect(remoteDataSource.connectionToken, 'session-token');
  });

  test('rejects empty and oversized chat messages before transport', () async {
    final remoteDataSource = FakeChatRemoteDataSource();
    final repository = ChatRepositoryImpl(
      remoteDataSource: remoteDataSource,
      currentUserId: '7',
      clientDio: Dio(),
    );

    final empty = await repository.sendChatMessage('  ');
    final oversized = await repository.sendChatMessage('x' * 4097);

    expect(empty, isA<Left<Failure, void>>());
    expect(oversized, isA<Left<Failure, void>>());
    expect(remoteDataSource.sent, isFalse);
  });

  test('sends message content without client identity or timestamps', () async {
    final remoteDataSource = FakeChatRemoteDataSource();
    final repository = ChatRepositoryImpl(
      remoteDataSource: remoteDataSource,
      currentUserId: '7',
      clientDio: Dio(),
    );

    final result = await repository.sendChatMessage('On my way');

    expect(result.isRight(), isTrue);
    expect(jsonDecode(remoteDataSource.sentPayload!), {
      'type': 'message',
      'text': 'On my way',
    });
  });

  test('sends typing status as an ephemeral chat event', () async {
    final remoteDataSource = FakeChatRemoteDataSource();
    final repository = ChatRepositoryImpl(
      remoteDataSource: remoteDataSource,
      currentUserId: '7',
      clientDio: Dio(),
    );

    final result = await repository.sendTypingStatus(true);

    expect(result.isRight(), isTrue);
    expect(jsonDecode(remoteDataSource.typingPayload!), {
      'type': 'typing',
      'is_typing': true,
    });
  });

  test('maps peer typing events without exposing transport details', () async {
    final remoteDataSource = FakeChatRemoteDataSource()
      ..eventStream = Stream<String>.value(
        jsonEncode({
          'type': 'typing',
          'room_id': '303',
          'sender_id': '8',
          'is_typing': true,
        }),
      );
    final repository = ChatRepositoryImpl(
      remoteDataSource: remoteDataSource,
      currentUserId: '7',
      clientDio: Dio(),
    );

    final event = await repository.chatEventsStream.first;

    ChatEvent? chatEvent;
    event.fold((_) {}, (value) => chatEvent = value);
    expect(chatEvent, isA<ChatTypingChanged>());
    final typingEvent = chatEvent! as ChatTypingChanged;
    expect(typingEvent.isTyping, isTrue);
    expect(typingEvent.isFromPeer, isTrue);
  });

  test('maps malformed chat history to a safe failure', () async {
    final remoteDataSource = FakeChatRemoteDataSource()
      ..eventStream = Stream<String>.value(
        jsonEncode({
          'type': 'history',
          'messages': ['malformed'],
        }),
      );
    final repository = ChatRepositoryImpl(
      remoteDataSource: remoteDataSource,
      currentUserId: '7',
      clientDio: Dio(),
    );

    final event = await repository.chatEventsStream.first;

    event.fold((failure) {
      expect(failure.message, 'Unable to read chat message.');
      expect(failure.message, isNot(contains('malformed')));
    }, (_) => fail('Expected malformed history to be rejected.'));
  });

  test('disposes the websocket data source with the repository', () async {
    final remoteDataSource = FakeChatRemoteDataSource();
    final repository = ChatRepositoryImpl(
      remoteDataSource: remoteDataSource,
      currentUserId: '7',
      clientDio: Dio(),
    );

    await repository.dispose();

    expect(remoteDataSource.disposed, isTrue);
  });
}

class _StubHttpClientAdapter(this._handler) implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => _handler(options);

  @override
  void close({bool force = false}) {}
}

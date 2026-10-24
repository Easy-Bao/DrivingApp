import 'dart:async';
import 'dart:convert';

import 'package:driver/src/features/chat/chat.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

class FakeChatRemoteDataSource implements ChatRemoteDataSource {
  bool sent = false;
  String? sentPayload;
  String? typingPayload;
  String? connectionToken;
  bool disposed = false;
  @override
  Stream<String> eventStream = const Stream.empty();
  Stream<ChatConnectionState> connectionStates = const Stream.empty();

  @override
  Future<void> connect(Uri chatServiceUri, {String? token}) async {
    connectionToken = token;
  }

  @override
  void sendMessage(String messagePayload) {
    sent = true;
    sentPayload = messagePayload;
  }

  @override
  void sendTypingStatus(bool isTyping) {
    typingPayload = jsonEncode({'type': 'typing', 'is_typing': isTyping});
  }

  @override
  Future<void> disconnect() async {}

  @override
  Stream<ChatConnectionState> get connectionStateStream => connectionStates;

  @override
  bool get isConnected => true;

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  for (final permission in [true, false, null, 'true']) {
    test(
      'maps counterparty calling permission strictly: $permission',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
          ..httpClientAdapter = _StubHttpClientAdapter((options) {
            expect(options.path, '/api/v1/rides/303/counterparty');
            return ResponseBody.fromString(
              jsonEncode({
                'name': 'Alex',
                'phone': '+639000000000',
                'contact_allowed': ?permission,
              }),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          });
        final repository = ChatRepositoryImpl(
          remoteDataSource: FakeChatRemoteDataSource(),
          currentUserId: '7',
          httpClient: dio,
        );
        final result = await repository.fetchPeer('303');
        result.fold((failure) => fail(failure.message), (peer) {
          expect(peer.phone, '+639000000000');
          expect(peer.canCall, permission == true);
        });
        await repository.dispose();
        dio.close();
      },
    );
  }

  for (final statusCode in [403, 423]) {
    test(
      'maps HTTP $statusCode room initialization to the correct access failure',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
          ..httpClientAdapter = _StubHttpClientAdapter(
            (_) => ResponseBody.fromString(
              '{}',
              statusCode,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            ),
          );
        final repository = ChatRepositoryImpl(
          remoteDataSource: FakeChatRemoteDataSource(),
          currentUserId: '7',
          httpClient: dio,
        );

        final result = await repository.initializeChatRoom(roomId: '303');

        result.fold(
          (failure) => expect(
            failure,
            statusCode == 423
                ? isA<ChatRoomLockedFailure>()
                : isNot(isA<ChatRoomLockedFailure>()),
          ),
          (_) => fail('Expected the closed chat failure.'),
        );
      },
    );

    test(
      'maps HTTP $statusCode message history to the correct access failure',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
          ..httpClientAdapter = _StubHttpClientAdapter(
            (_) => ResponseBody.fromString(
              '{}',
              statusCode,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            ),
          );
        final repository = ChatRepositoryImpl(
          remoteDataSource: FakeChatRemoteDataSource(),
          currentUserId: '7',
          httpClient: dio,
        );

        final result = await repository.fetchRoomMessages('303');

        result.fold(
          (failure) => expect(
            failure,
            statusCode == 423
                ? isA<ChatRoomLockedFailure>()
                : isNot(isA<ChatRoomLockedFailure>()),
          ),
          (_) => fail('Expected the closed chat failure.'),
        );
      },
    );
  }

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
      httpClient: dio,
    );

    final result = await repository.initializeChatRoom(roomId: '303');

    expect(result.isOk, isTrue);
    expect(capturedRequest?.path, '/api/v1/chat/rooms');
    expect(capturedRequest?.data, {'ride_id': '303'});
  });

  test('obtains the websocket token from its composition root', () async {
    final remoteDataSource = FakeChatRemoteDataSource();
    final repository = ChatRepositoryImpl(
      remoteDataSource: remoteDataSource,
      currentUserId: '7',
      httpClient: Dio(),
      tokenProvider: () async => 'session-token',
    );

    final result = await repository.establishChatConnection(
      roomId: '303',
      chatUri: Uri.parse('ws://localhost/chat'),
    );

    expect(result.isOk, isTrue);
    expect(remoteDataSource.connectionToken, 'session-token');
  });

  test('rejects empty and oversized chat messages before transport', () async {
    final remoteDataSource = FakeChatRemoteDataSource();
    final repository = ChatRepositoryImpl(
      remoteDataSource: remoteDataSource,
      currentUserId: '7',
      httpClient: Dio(),
    );

    final empty = await repository.sendChatMessage('  ');
    final oversized = await repository.sendChatMessage('x' * 4097);

    expect(empty, isA<Err<void, Failure>>());
    expect(oversized, isA<Err<void, Failure>>());
    expect(remoteDataSource.sent, isFalse);
  });

  test('sends message content without client identity or timestamps', () async {
    final remoteDataSource = FakeChatRemoteDataSource();
    final repository = ChatRepositoryImpl(
      remoteDataSource: remoteDataSource,
      currentUserId: '7',
      httpClient: Dio(),
    );

    final result = await repository.sendChatMessage('On my way');

    expect(result.isOk, isTrue);
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
      httpClient: Dio(),
    );

    final result = await repository.sendTypingStatus(true);

    expect(result.isOk, isTrue);
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
      httpClient: Dio(),
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
      httpClient: Dio(),
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
      httpClient: Dio(),
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

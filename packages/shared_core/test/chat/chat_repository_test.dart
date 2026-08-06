import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_core/shared_core.dart';

class FakeChatRemoteDataSource implements ChatRemoteDataSource {
  bool sent = false;
  bool disposed = false;

  @override
  Future<void> establishWebSocketConnection(
    Uri chatServiceUri, {
    String? token,
  }) async {}

  @override
  void sendWebSocketChatMessage(String messagePayload) {
    sent = true;
  }

  @override
  Future<void> terminateWebSocketConnection() async {}

  @override
  Stream<String> get webSocketEventStream => const Stream.empty();

  @override
  bool get isWebSocketConnected => true;

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  test('rejects empty and oversized chat messages before transport', () async {
    final remoteDataSource = FakeChatRemoteDataSource();
    final repository = ChatRepository(
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

  test('disposes the websocket data source with the repository', () async {
    final remoteDataSource = FakeChatRemoteDataSource();
    final repository = ChatRepository(
      remoteDataSource: remoteDataSource,
      currentUserId: '7',
      clientDio: Dio(),
    );

    await repository.dispose();

    expect(remoteDataSource.disposed, isTrue);
  });
}

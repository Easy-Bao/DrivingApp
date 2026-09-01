import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test(
    'forwards each valid event once with authenticated transport headers',
    () async {
      final socket = _Socket();
      final connector = _Connector(socket);
      final client = RealtimeWebSocketClient(
        uri: Uri.parse('ws://example.test/api/v1/realtime/ws'),
        tokenProvider: () => 'access-token',
        connector: connector,
        reconnectDelay: (_) => const Duration(days: 1),
      );
      final events = <Object>[];
      final subscription = client.events.listen(events.add);

      await client.start();
      socket.add(_eventJson('event-1'));
      socket.add(_eventJson('event-1'));
      await Future<void>.delayed(Duration.zero);

      expect(connector.headers, {'Authorization': 'Bearer access-token'});
      expect(events, hasLength(1));
      await subscription.cancel();
      await client.dispose();
    },
  );

  test('stop closes its socket and prevents reconnecting', () async {
    final socket = _Socket();
    final client = RealtimeWebSocketClient(
      uri: Uri.parse('ws://example.test/api/v1/realtime/ws'),
      tokenProvider: () => 'access-token',
      connector: _Connector(socket),
      reconnectDelay: (_) => Duration.zero,
    );

    await client.start();
    await client.stop();
    await socket.close();
    await Future<void>.delayed(Duration.zero);

    expect(socket.wasClosed, isTrue);
    expect(client.isConnected, isFalse);
    await client.dispose();
  });
}

String _eventJson(String id) =>
    '''{
  "id":"$id",
  "version":1,
  "type":"ride.status.changed",
  "occurred_at":"2026-08-10T10:00:00.000Z",
  "scope":{"ride_id":"ride-1","driver_id":"driver-1"},
  "payload":{"status":"accepted"}
}''';

final class _Connector(this.socket) implements RealtimeSocketConnector {
  final RealtimeSocket socket;
  Map<String, String>? headers;

  @override
  Future<RealtimeSocket> connect(
    Uri _, {
    required Map<String, String> headers,
  }) async {
    this.headers = headers;
    return socket;
  }
}

final class _Socket implements RealtimeSocket {
  final _messages = StreamController<Object?>.broadcast();
  bool wasClosed = false;

  @override
  Stream<Object?> get messages => _messages.stream;

  void add(String value) => _messages.add(value);

  @override
  Future<void> close() async {
    wasClosed = true;
    await _messages.close();
  }
}

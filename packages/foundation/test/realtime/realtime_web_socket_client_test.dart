import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test('uses the server-compatible heartbeat interval', () {
    expect(realtimeHeartbeatInterval, const Duration(seconds: 54));
  });

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

  test('reconnects immediately when network availability drops', () async {
    final firstSocket = _Socket();
    final secondSocket = _Socket();
    final connector = _SequenceConnector([firstSocket, secondSocket]);
    final network = NetworkAvailabilityCoordinator(failureThreshold: 1);
    final client = RealtimeWebSocketClient(
      uri: Uri.parse('ws://example.test/api/v1/realtime/ws'),
      tokenProvider: () => 'access-token',
      connector: connector,
      networkAvailability: network,
      reconnectDelay: (_) => const Duration(days: 1),
    );

    await client.start();
    network.recordFailure();
    await client.reconnectNow();
    await connector.secondConnection.future.timeout(const Duration(seconds: 1));

    expect(firstSocket.wasClosed, isTrue);
    expect(client.isConnected, isTrue);
    await client.dispose();
    await network.dispose();
  });

  test('uses full jitter within the exponential reconnect cap', () async {
    final states = <RealtimeConnectionState>[];
    final client = RealtimeWebSocketClient(
      uri: Uri.parse('ws://example.test/api/v1/realtime/ws'),
      tokenProvider: () => 'access-token',
      connector: _AlwaysFailConnector(),
      reconnectDelay: (_) => const Duration(seconds: 10),
      random: Random(1),
    );
    final subscription = client.states.listen(states.add);

    await client.start();
    await Future<void>.delayed(Duration.zero);

    final disconnected = states.whereType<RealtimeDisconnected>().last;
    expect(
      disconnected.reconnectIn,
      lessThanOrEqualTo(const Duration(seconds: 10)),
    );
    expect(disconnected.reconnectIn, greaterThanOrEqualTo(Duration.zero));

    await subscription.cancel();
    await client.dispose();
  });

  test(
    'refreshes credentials before a later failed reconnect attempt',
    () async {
      var accessToken = 'old-token';
      var refreshCount = 0;
      final connected = Completer<void>();
      final connector = _FailThenConnectConnector(connected);
      final client = RealtimeWebSocketClient(
        uri: Uri.parse('ws://example.test/api/v1/realtime/ws'),
        tokenProvider: () async => accessToken,
        refreshToken: () async {
          refreshCount++;
          accessToken = 'new-token';
          return accessToken;
        },
        connector: connector,
        reconnectDelay: (_) => Duration.zero,
      );

      await client.start();
      await connected.future.timeout(const Duration(seconds: 1));

      expect(refreshCount, 1);
      expect(connector.headers.last, {'Authorization': 'Bearer new-token'});
      await client.dispose();
    },
  );

  test(
    'cancels a dropped socket subscription and resynchronizes once',
    () async {
      final firstSocket = _Socket();
      final secondSocket = _Socket();
      final connector = _SequenceConnector([firstSocket, secondSocket]);
      final resynced = Completer<void>();
      var resyncCount = 0;
      final client = RealtimeWebSocketClient(
        uri: Uri.parse('ws://example.test/api/v1/realtime/ws'),
        tokenProvider: () => 'access-token',
        onResyncActiveTrip: () {
          resyncCount++;
          if (!resynced.isCompleted) resynced.complete();
          return Future<void>.value();
        },
        connector: connector,
        reconnectDelay: (_) => Duration.zero,
      );

      await client.start();
      await firstSocket.close();
      await connector.secondConnection.future.timeout(
        const Duration(seconds: 1),
      );
      await resynced.future.timeout(const Duration(seconds: 1));

      expect(firstSocket.subscriptionCancelled, isTrue);
      expect(resyncCount, 1);
      await client.dispose();
    },
  );

  test('coalesces concurrent active-trip resynchronization requests', () async {
    final release = Completer<void>();
    var resyncCount = 0;
    final socket = _Socket();
    final client = RealtimeWebSocketClient(
      uri: Uri.parse('ws://example.test/api/v1/realtime/ws'),
      tokenProvider: () => 'access-token',
      onResyncActiveTrip: () {
        resyncCount++;
        return release.future;
      },
      connector: _Connector(socket),
    );

    await client.start();
    final first = client.resyncActiveTrip();
    final second = client.resyncActiveTrip();

    expect(identical(first, second), isTrue);
    expect(resyncCount, 1);
    release.complete();
    await Future.wait([first, second]);
    await client.dispose();
  });

  test(
    'accepts a screen-scoped resync handler after socket construction',
    () async {
      final firstSocket = _Socket();
      final secondSocket = _Socket();
      final connector = _SequenceConnector([firstSocket, secondSocket]);
      final resynced = Completer<void>();
      var resyncCount = 0;
      final client = RealtimeWebSocketClient(
        uri: Uri.parse('ws://example.test/api/v1/realtime/ws'),
        tokenProvider: () => 'access-token',
        connector: connector,
        reconnectDelay: (_) => Duration.zero,
      );

      await client.start();
      client.setActiveTripResyncHandler(() {
        resyncCount++;
        if (!resynced.isCompleted) resynced.complete();
        return Future<void>.value();
      });
      await firstSocket.close();
      await connector.secondConnection.future.timeout(
        const Duration(seconds: 1),
      );
      await resynced.future.timeout(const Duration(seconds: 1));

      expect(resyncCount, 1);
      await client.dispose();
    },
  );

  test('reconnects when network availability recovers', () async {
    final firstSocket = _Socket();
    final secondSocket = _Socket();
    final connector = _SequenceConnector([firstSocket, secondSocket]);
    final availability = NetworkAvailabilityCoordinator(failureThreshold: 1);
    final client = RealtimeWebSocketClient(
      uri: Uri.parse('ws://example.test/api/v1/realtime/ws'),
      tokenProvider: () => 'access-token',
      connector: connector,
      networkAvailability: availability,
      reconnectDelay: (_) => const Duration(hours: 1),
    );

    await client.start();
    final reconnectedState = client.states.firstWhere(
      (state) => state is RealtimeConnected,
    );
    availability.recordFailure();
    availability.recordSuccess();

    await reconnectedState.timeout(const Duration(seconds: 1));
    expect(client.isConnected, isTrue);
    await client.dispose();
    await availability.dispose();
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
  late final StreamController<Object?> _messages;
  bool wasClosed = false;
  bool subscriptionCancelled = false;

  _Socket() {
    _messages = StreamController<Object?>.broadcast(
      onCancel: () => subscriptionCancelled = true,
    );
  }

  @override
  Stream<Object?> get messages => _messages.stream;

  void add(String value) => _messages.add(value);

  @override
  Future<void> close() async {
    wasClosed = true;
    await _messages.close();
  }
}

final class _SequenceConnector implements RealtimeSocketConnector {
  _SequenceConnector(this._sockets);

  final List<RealtimeSocket> _sockets;
  final secondConnection = Completer<void>();
  var _connectionCount = 0;

  @override
  Future<RealtimeSocket> connect(
    Uri _, {
    required Map<String, String> headers,
  }) async {
    final socket = _sockets[_connectionCount++];
    if (_connectionCount == 2) {
      if (!secondConnection.isCompleted) secondConnection.complete();
    }
    return socket;
  }
}

final class _FailThenConnectConnector(this._connected)
    implements RealtimeSocketConnector {
  final Completer<void> _connected;
  final headers = <Map<String, String>>[];
  var _attempt = 0;

  @override
  Future<RealtimeSocket> connect(
    Uri _, {
    required Map<String, String> headers,
  }) async {
    this.headers.add(headers);
    _attempt++;
    if (_attempt < 3) {
      throw StateError('connection rejected');
    }
    if (!_connected.isCompleted) _connected.complete();
    return _Socket();
  }
}

final class _AlwaysFailConnector implements RealtimeSocketConnector {
  @override
  Future<RealtimeSocket> connect(
    Uri _, {
    required Map<String, String> headers,
  }) async {
    throw StateError('connection rejected');
  }
}

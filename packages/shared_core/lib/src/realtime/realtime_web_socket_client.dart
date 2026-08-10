import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shared_core/src/realtime/realtime_event.dart';

typedef RealtimeTokenProvider = FutureOr<String?> Function();
typedef ReconnectDelay = Duration Function(int attempt);

abstract interface class RealtimeSocket {
  Stream<Object?> get messages;

  Future<void> close();
}

abstract interface class RealtimeSocketConnector {
  Future<RealtimeSocket> connect(
    Uri uri, {
    required Map<String, String> headers,
  });
}

final class IoRealtimeSocketConnector implements RealtimeSocketConnector {
  const IoRealtimeSocketConnector();

  @override
  Future<RealtimeSocket> connect(
    Uri uri, {
    required Map<String, String> headers,
  }) async => _IoRealtimeSocket(
    await WebSocket.connect(uri.toString(), headers: headers),
  );
}

final class _IoRealtimeSocket implements RealtimeSocket {
  const _IoRealtimeSocket(this._socket);

  final WebSocket _socket;

  @override
  Stream<Object?> get messages => _socket.cast<Object?>();

  @override
  Future<void> close() => _socket.close();
}

sealed class RealtimeConnectionState {
  const RealtimeConnectionState();
}

final class RealtimeDisconnected extends RealtimeConnectionState {
  const RealtimeDisconnected({this.reconnectIn});

  final Duration? reconnectIn;
}

final class RealtimeConnecting extends RealtimeConnectionState {
  const RealtimeConnecting(this.attempt);

  final int attempt;
}

final class RealtimeConnected extends RealtimeConnectionState {
  const RealtimeConnected();
}

/// Maintains one authenticated event stream for a signed-in app session.
/// Snapshot refresh remains the caller's responsibility after a reconnect.
final class RealtimeWebSocketClient {
  RealtimeWebSocketClient({
    required Uri uri,
    required RealtimeTokenProvider tokenProvider,
    RealtimeSocketConnector connector = const IoRealtimeSocketConnector(),
    ReconnectDelay? reconnectDelay,
    Random? random,
  }) : _uri = uri,
       _tokenProvider = tokenProvider,
       _connector = connector,
       _reconnectDelay = reconnectDelay ?? _defaultReconnectDelay,
       _random = random ?? Random();

  static const _maximumDuplicateIds = 256;

  final Uri _uri;
  final RealtimeTokenProvider _tokenProvider;
  final RealtimeSocketConnector _connector;
  final ReconnectDelay _reconnectDelay;
  final Random _random;
  final _events = StreamController<RealtimeEvent>.broadcast();
  final _states = StreamController<RealtimeConnectionState>.broadcast();
  final _seenIds = <String>{};

  RealtimeSocket? _socket;
  // Cancellation is owned by stop and dispose so a reconnect can replace it.
  // ignore: cancel_subscriptions
  StreamSubscription<Object?>? _socketSubscription;
  Timer? _reconnectTimer;
  Future<void>? _connecting;
  bool _wanted = false;
  bool _disposed = false;
  int _attempt = 0;

  Stream<RealtimeEvent> get events => _events.stream;
  Stream<RealtimeConnectionState> get states => _states.stream;
  bool get isConnected => _socket != null;

  Future<void> start() {
    if (_disposed) {
      throw StateError('RealtimeWebSocketClient has been disposed.');
    }
    _wanted = true;
    return _connect();
  }

  Future<void> stop() async {
    _wanted = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final subscription = _socketSubscription;
    _socketSubscription = null;
    await subscription?.cancel();
    final socket = _socket;
    _socket = null;
    await socket?.close();
    _emitState(const RealtimeDisconnected());
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await stop();
    await _events.close();
    await _states.close();
  }

  Future<void> _connect() {
    final active = _connecting;
    if (active != null) {
      return active;
    }
    final connection = _open();
    _connecting = connection;
    return connection.whenComplete(() {
      if (identical(_connecting, connection)) {
        _connecting = null;
      }
    });
  }

  Future<void> _open() async {
    if (!_wanted || _disposed || _socket != null) {
      return;
    }
    _emitState(RealtimeConnecting(_attempt));
    try {
      final token = await _tokenProvider();
      if (token == null || token.trim().isEmpty) {
        throw StateError('Realtime authentication token is unavailable.');
      }
      final socket = await _connector.connect(
        _uri,
        headers: {'Authorization': 'Bearer ${token.trim()}'},
      );
      if (!_wanted || _disposed) {
        await socket.close();
        return;
      }
      _socket = socket;
      _attempt = 0;
      // ignore: cancel_subscriptions
      _socketSubscription = socket.messages.listen(
        _onMessage,
        onError: (Object error, StackTrace stackTrace) => _onDisconnect(socket),
        onDone: () => _onDisconnect(socket),
      );
      _emitState(const RealtimeConnected());
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onMessage(Object? message) {
    if (message is! String) {
      return;
    }
    try {
      final decoded = jsonDecode(message);
      if (decoded is! Map) {
        return;
      }
      final realtimeEvent = RealtimeEvent.fromEnvelope(
        RealtimeEnvelope.fromJson(Map<String, dynamic>.from(decoded)),
      );
      if (_remember(realtimeEvent.envelope.id)) {
        _events.add(realtimeEvent);
      }
    } on FormatException {
      // Malformed messages are isolated to this transient delivery attempt.
    } on TypeError {
      // Invalid JSON shapes are isolated to this transient delivery attempt.
    }
  }

  void _onDisconnect(RealtimeSocket socket) {
    if (!identical(_socket, socket)) {
      return;
    }
    _socket = null;
    _socketSubscription = null;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_wanted || _disposed || _reconnectTimer != null) {
      return;
    }
    _attempt += 1;
    final baseDelay = _reconnectDelay(_attempt);
    final jitterMilliseconds = _random.nextInt(
      max(1, baseDelay.inMilliseconds ~/ 4),
    );
    final delay = baseDelay + Duration(milliseconds: jitterMilliseconds);
    _emitState(RealtimeDisconnected(reconnectIn: delay));
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      unawaited(_connect());
    });
  }

  bool _remember(String id) {
    if (_seenIds.contains(id)) {
      return false;
    }
    _seenIds.add(id);
    if (_seenIds.length > _maximumDuplicateIds) {
      _seenIds.remove(_seenIds.first);
    }
    return true;
  }

  void _emitState(RealtimeConnectionState state) {
    if (!_states.isClosed) {
      _states.add(state);
    }
  }

  static Duration _defaultReconnectDelay(int attempt) {
    final boundedAttempt = attempt.clamp(1, 6);
    return Duration(seconds: min(30, 1 << (boundedAttempt - 1)));
  }
}

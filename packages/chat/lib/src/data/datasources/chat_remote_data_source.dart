import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:chat/src/domain/entities/chat_connection_state.dart';
import 'package:foundation/foundation.dart';

abstract class ChatRemoteDataSource {
  Future<void> connect(Uri chatServiceUri, {String? token});

  void sendMessage(String messagePayload);

  void sendTypingStatus(bool isTyping);

  Future<void> disconnect();

  Stream<String> get eventStream;

  Stream<ChatConnectionState> get connectionStateStream =>
      const Stream<ChatConnectionState>.empty();

  bool get isConnected;

  Future<void> dispose();
}

class ChatRemoteDataSourceImpl({
  FutureOr<String?> Function()? tokenProvider,
  Future<String?> Function()? refreshTokenProvider,
  NetworkAvailabilityCoordinator? networkAvailability,
  math.Random? random,
}) implements ChatRemoteDataSource {
  static const _connectionTimeout = Duration(seconds: 15);
  static const _pingInterval = Duration(seconds: 20);
  static const _maximumReconnectAttempt = 6;
  static const _maxPendingMessages = 100;

  WebSocket? _chatWebSocket;
  bool _disposed = false;
  bool _shouldReconnect = false;
  Uri? _chatServiceUri;
  String? _token;
  final FutureOr<String?> Function()? _tokenProvider = tokenProvider;
  final Future<String?> Function()? _refreshTokenProvider =
      refreshTokenProvider;
  final NetworkAvailabilityCoordinator? _networkAvailability =
      networkAvailability;
  final math.Random _random = random ?? math.Random();
  int _connectionVersion = 0;
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;
  final List<String> _pendingChatMessages = <String>[];
  StreamSubscription<dynamic>? _socketSubscription;
  final StreamController<String> _chatEventStreamController =
      StreamController<String>.broadcast();
  final StreamController<ChatConnectionState> _connectionStateController =
      StreamController<ChatConnectionState>.broadcast();

  @override
  Stream<String> get eventStream => _chatEventStreamController.stream;

  @override
  Stream<ChatConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  bool get isConnected {
    final socket = _chatWebSocket;
    return socket != null && socket.readyState == WebSocket.open;
  }

  @override
  Future<void> connect(Uri chatServiceUri, {String? token}) async {
    if (_disposed) {
      throw StateError('Chat transport has been disposed.');
    }
    await disconnect();
    if (_disposed) {
      throw StateError('Chat transport has been disposed.');
    }
    _shouldReconnect = true;
    _chatServiceUri = chatServiceUri;
    _token = token;
    _reconnectAttempt = 0;
    await _openConnection(reportFailure: true);
  }

  @override
  void sendMessage(String messagePayload) {
    if (_disposed) {
      throw StateError('Chat connection is unavailable.');
    }
    final socket = _chatWebSocket;
    if (socket == null || socket.readyState != WebSocket.open) {
      _enqueuePending(messagePayload);
      return;
    }
    try {
      socket.add(messagePayload);
    } catch (_) {
      _enqueuePending(messagePayload);
    }
  }

  @override
  void sendTypingStatus(bool isTyping) {
    final socket = _chatWebSocket;
    if (_disposed || socket == null || socket.readyState != WebSocket.open) {
      throw StateError('Chat connection is unavailable.');
    }
    socket.add(jsonEncode({'type': 'typing', 'is_typing': isTyping}));
  }

  @override
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _connectionVersion++;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final subscription = _socketSubscription;
    _socketSubscription = null;
    final socket = _chatWebSocket;
    _chatWebSocket = null;
    await _cancelSocketSubscription(subscription);
    await socket?.close();
    _pendingChatMessages.clear();
    _emitConnectionState(const ChatDisconnected());
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await disconnect();
    await _chatEventStreamController.close();
    await _connectionStateController.close();
  }

  Future<void> _openConnection({required bool reportFailure}) async {
    final uri = _chatServiceUri;
    if (!_shouldReconnect || _disposed || uri == null) return;

    final coordinator = _networkAvailability;
    if (coordinator != null &&
        coordinator.status == NetworkAvailabilityStatus.unavailable &&
        !reportFailure) {
      _scheduleReconnect();
      return;
    }

    final connectionVersion = _connectionVersion;
    _emitConnectionState(ChatConnecting(_reconnectAttempt));

    try {
      final token = _tokenProvider == null
          ? _token
          : await _tokenProvider.call();
      if (!_shouldReconnect ||
          _disposed ||
          connectionVersion != _connectionVersion) {
        return;
      }

      final socket = await WebSocket.connect(
        uri.toString(),
        headers: token == null || token.trim().isEmpty
            ? null
            : {'Authorization': 'Bearer ${token.trim()}'},
      ).timeout(_connectionTimeout);

      if (!_shouldReconnect ||
          _disposed ||
          connectionVersion != _connectionVersion) {
        await socket.close();
        return;
      }

      socket.pingInterval = _pingInterval;
      _chatWebSocket = socket;
      _reconnectAttempt = 0;
      _emitConnectionState(const ChatConnected());
      _socketSubscription = socket.listen(
        (event) {
          if (!_disposed &&
              !_chatEventStreamController.isClosed &&
              event is String) {
            _chatEventStreamController.add(event);
          }
        },
        onError: (Object error) {
          if (!_disposed && !_chatEventStreamController.isClosed) {
            _chatEventStreamController.addError(
              StateError('Chat transport failed.'),
            );
          }
          _handleSocketDisconnect(socket);
        },
        onDone: () => _handleSocketDisconnect(socket),
      );
      _flushPendingChatMessages();
    } catch (error, stackTrace) {
      if (connectionVersion != _connectionVersion ||
          !_shouldReconnect ||
          _disposed) {
        return;
      }
      if (_shouldRefreshToken(error) || _reconnectAttempt > 0) {
        try {
          await _refreshTokenProvider?.call();
        } catch (_) {
          // The regular reconnect schedule remains responsible for recovery.
        }
      }
      _scheduleReconnect();
      if (reportFailure) {
        Error.throwWithStackTrace(error, stackTrace);
      }
    }
  }

  bool _shouldRefreshToken(Object error) {
    if (error is WebSocketException) {
      return error.message.contains('401') || error.message.contains('403');
    }
    return false;
  }

  void _enqueuePending(String payload) {
    if (_pendingChatMessages.length >= _maxPendingMessages) {
      _pendingChatMessages.removeAt(0);
    }
    _pendingChatMessages.add(payload);
  }

  void _handleSocketDisconnect(WebSocket socket) {
    if (!identical(_chatWebSocket, socket)) return;
    final subscription = _socketSubscription;
    _socketSubscription = null;
    _chatWebSocket = null;
    if (subscription != null) {
      unawaited(_cancelSocketSubscription(subscription));
    }
    _scheduleReconnect();
  }

  Future<void> _cancelSocketSubscription(
    StreamSubscription<dynamic>? subscription,
  ) async {
    try {
      await subscription?.cancel();
    } catch (_) {
      // The socket is already in its disconnect path; no recovery action is
      // possible for a failed cancellation.
    }
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect || _disposed || _reconnectTimer != null) return;

    _reconnectAttempt = (_reconnectAttempt + 1).clamp(
      1,
      _maximumReconnectAttempt,
    );
    final baseSeconds = 1 << (_reconnectAttempt - 1);
    final jitterFactor = 0.8 + (_random.nextDouble() * 0.4);
    final delay = Duration(
      milliseconds: (baseSeconds * 1000 * jitterFactor).round(),
    );
    _emitConnectionState(ChatDisconnected(reconnectIn: delay));
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      unawaited(_openConnection(reportFailure: false));
    });
  }

  void _flushPendingChatMessages() {
    final socket = _chatWebSocket;
    if (socket == null || socket.readyState != WebSocket.open) return;
    while (_pendingChatMessages.isNotEmpty) {
      final payload = _pendingChatMessages.first;
      try {
        socket.add(payload);
        _pendingChatMessages.removeAt(0);
      } catch (_) {
        return;
      }
    }
  }

  void _emitConnectionState(ChatConnectionState state) {
    if (!_disposed && !_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
  }
}

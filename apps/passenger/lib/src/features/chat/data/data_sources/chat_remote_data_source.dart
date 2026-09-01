import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:passenger/src/features/chat/domain/entities/chat_connection_state.dart';

abstract class ChatRemoteDataSource {
  Future<void> establishWebSocketConnection(
    Uri chatServiceUri, {
    String? token,
  });

  void sendWebSocketChatMessage(String messagePayload);

  void sendWebSocketTypingStatus(bool isTyping);

  Future<void> terminateWebSocketConnection();

  Stream<String> get webSocketEventStream;

  /// Connection changes are separate from chat payloads so a reconnect never
  /// has to be represented as a fake user message or a raw transport error.
  Stream<ChatConnectionState> get connectionStateStream =>
      const Stream<ChatConnectionState>.empty();

  bool get isWebSocketConnected;

  Future<void> dispose();
}

class WebSocketChatRemoteDataSource implements ChatRemoteDataSource {
  static const _connectionTimeout = Duration(seconds: 15);
  static const _maximumReconnectAttempt = 6;

  WebSocket? _chatWebSocket;
  bool _disposed = false;
  bool _shouldReconnect = false;
  Uri? _chatServiceUri;
  String? _token;
  int _connectionVersion = 0;
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;
  final StreamController<String> _chatEventStreamController =
      StreamController<String>.broadcast();
  final StreamController<ChatConnectionState> _connectionStateController =
      StreamController<ChatConnectionState>.broadcast();

  @override
  Stream<String> get webSocketEventStream => _chatEventStreamController.stream;

  @override
  Stream<ChatConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  bool get isWebSocketConnected {
    final socket = _chatWebSocket;
    return socket != null && socket.readyState == WebSocket.open;
  }

  @override
  Future<void> establishWebSocketConnection(
    Uri chatServiceUri, {
    String? token,
  }) async {
    await terminateWebSocketConnection();
    _disposed = false;
    _shouldReconnect = true;
    _chatServiceUri = chatServiceUri;
    _token = token;
    _reconnectAttempt = 0;
    await _openConnection(reportFailure: true);
  }

  @override
  void sendWebSocketChatMessage(String messagePayload) {
    final socket = _chatWebSocket;
    if (socket == null || socket.readyState != WebSocket.open) {
      throw StateError('Chat connection is unavailable.');
    }
    socket.add(messagePayload);
  }

  @override
  void sendWebSocketTypingStatus(bool isTyping) {
    final socket = _chatWebSocket;
    if (socket == null || socket.readyState != WebSocket.open) {
      throw StateError('Chat connection is unavailable.');
    }
    socket.add(jsonEncode({'type': 'typing', 'is_typing': isTyping}));
  }

  @override
  Future<void> terminateWebSocketConnection() async {
    _shouldReconnect = false;
    _connectionVersion++;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final socket = _chatWebSocket;
    _chatWebSocket = null;
    await socket?.close();
    _emitConnectionState(const ChatDisconnected());
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await terminateWebSocketConnection();
    await _chatEventStreamController.close();
    await _connectionStateController.close();
  }

  Future<void> _openConnection({required bool reportFailure}) async {
    final uri = _chatServiceUri;
    if (!_shouldReconnect || _disposed || uri == null) return;

    final connectionVersion = _connectionVersion;
    _emitConnectionState(ChatConnecting(_reconnectAttempt));

    try {
      final token = _token;
      final socket = await WebSocket.connect(
        uri.toString(),
        headers: token == null || token.isEmpty
            ? null
            : {'Authorization': 'Bearer $token'},
      ).timeout(_connectionTimeout);

      if (!_shouldReconnect ||
          _disposed ||
          connectionVersion != _connectionVersion) {
        await socket.close();
        return;
      }

      _chatWebSocket = socket;
      _reconnectAttempt = 0;
      _emitConnectionState(const ChatConnected());
      socket.listen(
        (event) {
          if (!_disposed && event is String) {
            _chatEventStreamController.add(event);
          }
        },
        onError: (Object error) {
          if (!_disposed) {
            _chatEventStreamController.addError(
              StateError('Chat transport failed.'),
            );
          }
          _handleSocketDisconnect(socket);
        },
        onDone: () => _handleSocketDisconnect(socket),
      );
    } catch (error, stackTrace) {
      if (connectionVersion != _connectionVersion || !_shouldReconnect) {
        return;
      }
      _scheduleReconnect();
      if (reportFailure) {
        Error.throwWithStackTrace(error, stackTrace);
      }
    }
  }

  void _handleSocketDisconnect(WebSocket socket) {
    if (!identical(_chatWebSocket, socket)) return;
    _chatWebSocket = null;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect || _disposed || _reconnectTimer != null) return;

    _reconnectAttempt = (_reconnectAttempt + 1).clamp(
      1,
      _maximumReconnectAttempt,
    );
    final delay = Duration(seconds: 1 << (_reconnectAttempt - 1));
    _emitConnectionState(ChatDisconnected(reconnectIn: delay));
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      unawaited(_openConnection(reportFailure: false));
    });
  }

  void _emitConnectionState(ChatConnectionState state) {
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(state);
    }
  }
}

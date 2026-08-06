import 'dart:async';
import 'dart:io';

abstract class ChatRemoteDataSource {
  Future<void> establishWebSocketConnection(
    Uri chatServiceUri, {
    String? token,
  });

  void sendWebSocketChatMessage(String messagePayload);

  Future<void> terminateWebSocketConnection();

  Stream<String> get webSocketEventStream;

  bool get isWebSocketConnected;

  Future<void> dispose();
}

class WebSocketChatRemoteDataSource implements ChatRemoteDataSource {
  WebSocket? _chatWebSocket;
  bool _disposed = false;
  final StreamController<String> _chatEventStreamController =
      StreamController<String>.broadcast();

  @override
  Stream<String> get webSocketEventStream => _chatEventStreamController.stream;

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
    final socket = await WebSocket.connect(
          chatServiceUri.toString(),
          headers: token == null || token.isEmpty
              ? null
              : {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));
    _chatWebSocket = socket;

    socket.listen(
      (event) {
        if (!_disposed && event is String) {
          _chatEventStreamController.add(event);
        }
      },
      onError: (error) {
        if (!_disposed) {
          _chatEventStreamController.addError(
            StateError('Chat transport failed'),
          );
        }
      },
      onDone: () {
        if (identical(_chatWebSocket, socket)) {
          unawaited(terminateWebSocketConnection());
        }
      },
    );
  }

  @override
  void sendWebSocketChatMessage(String messagePayload) {
    final socket = _chatWebSocket;
    if (socket != null && socket.readyState == WebSocket.open) {
      socket.add(messagePayload);
    }
  }

  @override
  Future<void> terminateWebSocketConnection() async {
    final socket = _chatWebSocket;
    _chatWebSocket = null;
    await socket?.close();
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await terminateWebSocketConnection();
    await _chatEventStreamController.close();
  }
}

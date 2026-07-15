import 'dart:async';
import 'dart:io';

/// Remote data source contract governing WebSockets chat room interactions.
abstract class ChatRemoteDataSource {
  /// Establishes an active WebSocket connection to the chat service at the specified URI.
  Future<void> establishWebSocketConnection(Uri chatServiceUri);

  /// Sends a raw text message payload across the WebSocket connection.
  void sendWebSocketChatMessage(String messagePayload);

  /// Closes the active WebSocket session and releases system resources.
  Future<void> terminateWebSocketConnection();

  /// A stream of raw string payloads received from the remote chat server.
  Stream<String> get webSocketEventStream;

  /// Returns whether the active socket session is successfully connected.
  bool get isWebSocketConnected;
}

/// Native WebSocket implementation of [ChatRemoteDataSource] using [WebSocket] from 'dart:io'.
class WebSocketChatRemoteDataSource implements ChatRemoteDataSource {
  WebSocket? _chatWebSocket;
  final StreamController<String> _chatEventStreamController =
      StreamController<String>.broadcast();

  @override
  Stream<String> get webSocketEventStream => _chatEventStreamController.stream;

  @override
  bool get isWebSocketConnected =>
      _chatWebSocket != null && _chatWebSocket!.readyState == WebSocket.open;

  @override
  Future<void> establishWebSocketConnection(Uri chatServiceUri) async {
    await terminateWebSocketConnection();
    final socket = await WebSocket.connect(chatServiceUri.toString());
    _chatWebSocket = socket;

    socket.listen(
      (event) {
        if (event is String) {
          _chatEventStreamController.add(event);
        }
      },
      onError: (error) {
        _chatEventStreamController.addError(error);
      },
      onDone: () {
        unawaited(terminateWebSocketConnection());
      },
    );
  }

  @override
  void sendWebSocketChatMessage(String messagePayload) {
    if (isWebSocketConnected) {
      _chatWebSocket!.add(messagePayload);
    }
  }

  @override
  Future<void> terminateWebSocketConnection() async {
    if (_chatWebSocket != null) {
      await _chatWebSocket!.close();
      _chatWebSocket = null;
    }
  }
}

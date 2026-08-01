import 'dart:async';
import 'dart:io';

abstract class ChatRemoteDataSource {
  Future<void> establishWebSocketConnection(Uri chatServiceUri);

  void sendWebSocketChatMessage(String messagePayload);

  Future<void> terminateWebSocketConnection();

  Stream<String> get webSocketEventStream;

  bool get isWebSocketConnected;
}

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

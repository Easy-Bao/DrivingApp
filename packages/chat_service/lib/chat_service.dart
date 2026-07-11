import 'dart:async';
import 'dart:convert';
import 'dart:io';

class ChatMessage {
  final String text;
  final String senderId;
  final bool isFromPeer;
  final DateTime createdAt;

  ChatMessage({
    required this.text,
    required this.senderId,
    required this.isFromPeer,
    required this.createdAt,
  });
}

class ChatService {
  WebSocket? _webSocketConnection;
  bool _isConnectionActive = false;
  bool _isRoomLocked = false;
  String _lockReasonMessage = '';
  final String _currentUserId;
  final List<ChatMessage> _chatHistoryMessages = [];

  final _chatUpdateStreamController = StreamController<void>.broadcast();

  ChatService({required String currentUserId})
      : _currentUserId = currentUserId;

  List<ChatMessage> get chatHistoryMessages => _chatHistoryMessages;
  bool get isConnectionActive => _isConnectionActive;
  bool get isRoomLocked => _isRoomLocked;
  String get lockReasonMessage => _lockReasonMessage;
  Stream<void> get chatUpdatesStream => _chatUpdateStreamController.stream;

  Future<void> connectToChatRoom({
    required String roomId,
    required String gatewayUrl,
    String? jsonWebToken,
  }) async {
    if (roomId.isEmpty) {
      throw ArgumentError('Room ID cannot be empty');
    }
    if (_currentUserId.isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }

    final wsProtocolScheme = gatewayUrl.startsWith('https') ? 'wss://' : 'ws://';
    final hostPortAddress = gatewayUrl
        .replaceAll('https://', '')
        .replaceAll('http://', '');
    final tokenQueryParam = jsonWebToken != null ? '&token=$jsonWebToken' : '';
    final completeWebSocketUrl =
        '$wsProtocolScheme$hostPortAddress/chat/ws?roomId=$roomId&userId=$_currentUserId$tokenQueryParam';

    try {
      // ignore: close_sinks
      final socket = await WebSocket.connect(completeWebSocketUrl);
      _webSocketConnection = socket;
      _isConnectionActive = true;
      _chatUpdateStreamController.add(null);

      socket.listen(
        (event) {
          final eventDataMap = jsonDecode(event as String) as Map<String, dynamic>;
          final eventType = eventDataMap['type'];

          if (eventType == 'history') {
            final messagesList = eventDataMap['messages'] as List;
            _chatHistoryMessages.clear();
            for (final msg in messagesList) {
              if (msg is Map<String, dynamic>) {
                final senderId = msg['senderId'] as String? ?? '';
                final isFromPeer = senderId != _currentUserId;
                _chatHistoryMessages.add(
                  ChatMessage(
                    text: msg['text'] as String? ?? '',
                    senderId: senderId,
                    isFromPeer: isFromPeer,
                    createdAt: DateTime.parse(msg['createdAt'] as String? ?? DateTime.now().toIso8601String()).toLocal(),
                  ),
                );
              }
            }
            _chatUpdateStreamController.add(null);
          } else if (eventType == 'message') {
            final senderId = eventDataMap['senderId'] as String? ?? '';
            final isFromPeer = senderId != _currentUserId;
            _chatHistoryMessages.add(
              ChatMessage(
                text: eventDataMap['text'] as String? ?? '',
                senderId: senderId,
                isFromPeer: isFromPeer,
                createdAt: DateTime.parse(eventDataMap['createdAt'] as String? ?? DateTime.now().toIso8601String()).toLocal(),
              ),
            );
            _chatUpdateStreamController.add(null);
          } else if (eventType == 'locked') {
            _isRoomLocked = true;
            _lockReasonMessage = eventDataMap['reason'] as String? ?? 'This conversation is locked.';
            _chatUpdateStreamController.add(null);
          }
        },
        onError: (_) {
          _isConnectionActive = false;
          _chatUpdateStreamController.add(null);
        },
        onDone: () {
          _isConnectionActive = false;
          _chatUpdateStreamController.add(null);
        },
      );
    } catch (_) {
      _isConnectionActive = false;
      _chatUpdateStreamController.add(null);
    }
  }

  void sendMessageToRoom(String text) {
    if (_isRoomLocked) return;
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) return;

    if (_webSocketConnection != null && _isConnectionActive) {
      _webSocketConnection!.add(jsonEncode({'text': normalizedText}));
    }
  }

  Future<void> disconnectChatRoom() async {
    if (_webSocketConnection != null) {
      await _webSocketConnection!.close();
    }
    _isConnectionActive = false;
    unawaited(_chatUpdateStreamController.close());
  }
}

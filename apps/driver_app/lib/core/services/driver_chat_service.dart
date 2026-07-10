import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:driver_app/core/config/env_config.dart';

class DriverChatMessage {
  final String text;
  final bool isPassenger;
  final DateTime createdAt;

  DriverChatMessage({
    required this.text,
    required this.isPassenger,
    required this.createdAt,
  });
}

class DriverChatService {
  WebSocket? _webSocketConnection;
  bool _isConnectionActive = false;
  bool _isRoomLocked = false;
  String _lockReasonMessage = '';
  final String _currentDriverId;
  final List<DriverChatMessage> _chatHistoryMessages = [];

  final _chatUpdateStreamController = StreamController<void>.broadcast();

  DriverChatService({required String currentDriverId})
      : _currentDriverId = currentDriverId;

  List<DriverChatMessage> get chatHistoryMessages => _chatHistoryMessages;
  bool get isConnectionActive => _isConnectionActive;
  bool get isRoomLocked => _isRoomLocked;
  String get lockReasonMessage => _lockReasonMessage;
  Stream<void> get chatUpdatesStream => _chatUpdateStreamController.stream;

  /**
   * Connects to the chat gateway server using a WebSocket connection.
   * Parses the driver service base URL, normalizes it, and constructs
   * the complete WebSocket URL dynamically.
   */
  Future<void> connectToChatRoom({
    required String roomId,
  }) async {
    if (roomId.isEmpty) {
      throw ArgumentError('Room ID cannot be empty');
    }
    if (_currentDriverId.isEmpty) {
      throw ArgumentError('Driver ID cannot be empty');
    }

    final serviceBaseUrl = EnvConfig.driverServiceUrl;
    final gatewayBaseUrl = serviceBaseUrl.replaceAll('8082', '8080');
    final wsProtocolScheme = gatewayBaseUrl.startsWith('https') ? 'wss://' : 'ws://';
    final hostPortAddress = gatewayBaseUrl
        .replaceAll('https://', '')
        .replaceAll('http://', '');
    final completeWebSocketUrl =
        '$wsProtocolScheme$hostPortAddress/chat/ws?roomId=$roomId&userId=$_currentDriverId';

    try {
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
                final isSenderPassenger = msg['senderId'] != _currentDriverId;
                _chatHistoryMessages.add(
                  DriverChatMessage(
                    text: msg['text'] as String,
                    isPassenger: isSenderPassenger,
                    createdAt: DateTime.parse(msg['createdAt'] as String).toLocal(),
                  ),
                );
              }
            }
            _chatUpdateStreamController.add(null);
          } else if (eventType == 'message') {
            final isSenderPassenger = eventDataMap['senderId'] != _currentDriverId;
            _chatHistoryMessages.add(
              DriverChatMessage(
                text: eventDataMap['text'] as String,
                isPassenger: isSenderPassenger,
                createdAt: DateTime.parse(eventDataMap['createdAt'] as String).toLocal(),
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
    _chatUpdateStreamController.close();
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:passenger_app/core/config/env_config.dart';

class PassengerChatMessage {
  final String text;
  final bool isDriver;
  final DateTime createdAt;

  PassengerChatMessage({
    required this.text,
    required this.isDriver,
    required this.createdAt,
  });
}

class PassengerChatService {
  WebSocket? _webSocketConnection;
  bool _isConnectionActive = false;
  bool _isRoomLocked = false;
  String _lockReasonMessage = '';
  final String _currentPassengerId;
  final List<PassengerChatMessage> _chatHistoryMessages = [];

  final _chatUpdateStreamController = StreamController<void>.broadcast();

  PassengerChatService({required String currentPassengerId})
      : _currentPassengerId = currentPassengerId;

  List<PassengerChatMessage> get chatHistoryMessages => _chatHistoryMessages;
  bool get isConnectionActive => _isConnectionActive;
  bool get isRoomLocked => _isRoomLocked;
  String get lockReasonMessage => _lockReasonMessage;
  Stream<void> get chatUpdatesStream => _chatUpdateStreamController.stream;

  /**
   * Connects to the chat gateway server using a WebSocket connection.
   * Parses the passenger service base URL, normalizes it, and constructs
   * the complete WebSocket URL dynamically.
   */
  Future<void> connectToChatRoom({
    required String roomId,
    String? jsonWebToken,
  }) async {
    if (roomId.isEmpty) {
      throw ArgumentError('Room ID cannot be empty');
    }
    if (_currentPassengerId.isEmpty) {
      throw ArgumentError('Passenger ID cannot be empty');
    }

    final serviceBaseUrl = EnvConfig.passengerServiceUrl;
    final gatewayBaseUrl = serviceBaseUrl.replaceAll('8081', '8080');
    final wsProtocolScheme = gatewayBaseUrl.startsWith('https') ? 'wss://' : 'ws://';
    final hostPortAddress = gatewayBaseUrl
        .replaceAll('https://', '')
        .replaceAll('http://', '');
    final tokenQueryParam = jsonWebToken != null ? '&token=$jsonWebToken' : '';
    final completeWebSocketUrl =
        '$wsProtocolScheme$hostPortAddress/chat/ws?roomId=$roomId&userId=$_currentPassengerId$tokenQueryParam';

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
            for (final msg in messagesList.cast<Map<String, dynamic>>()) {
              final isSenderDriver = msg['senderId'] != _currentPassengerId;
              _chatHistoryMessages.add(
                PassengerChatMessage(
                  text: msg['text'] as String,
                  isDriver: isSenderDriver,
                  createdAt: DateTime.parse(msg['createdAt'] as String).toLocal(),
                ),
              );
            }
            _chatUpdateStreamController.add(null);
          } else if (eventType == 'message') {
            final isSenderDriver = eventDataMap['senderId'] != _currentPassengerId;
            _chatHistoryMessages.add(
              PassengerChatMessage(
                text: eventDataMap['text'] as String,
                isDriver: isSenderDriver,
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
    unawaited(_chatUpdateStreamController.close());
  }
}

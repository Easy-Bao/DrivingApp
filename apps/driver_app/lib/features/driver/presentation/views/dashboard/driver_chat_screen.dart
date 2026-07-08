import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:driver_app/core/themes/app_themes.dart';
import 'package:driver_app/core/config/env_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:http/http.dart' as http;

class DriverChatScreen extends StatefulWidget {
  final String? roomId;
  final String? userId;
  final String? peerName;

  const DriverChatScreen({super.key, this.roomId, this.userId, this.peerName});

  @override
  State<DriverChatScreen> createState() => _DriverChatScreenState();
}

class _DriverChatScreenState extends State<DriverChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_Msg> _msgs = [];
  late AnimationController _typingCtrl;
  final _passengerTyping = false;
  WebSocket? _socket;
  bool _isConnected = false;
  bool _isChatRoomLocked = false;
  String _lockWarningMessageText = '';

  Future<void> _resolveChatRoom() async {
    final chatRoomId = widget.roomId ?? 'test-room-123';
    try {
      final driverServiceUrl = EnvConfig.driverServiceUrl;
      final gatewayUrl = driverServiceUrl.replaceAll('8082', '8080');
      final resolveEndpointUrl = '$gatewayUrl/chat/rooms/$chatRoomId/resolve';

      final resolveResponse = await http.post(
        Uri.parse(resolveEndpointUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (resolveResponse.statusCode == 200) {
        setState(() {
          _isChatRoomLocked = true;
          _lockWarningMessageText = 'This conversation has been resolved.';
        });
      }
    } catch (_) {}
  }

  final _quickReplies = [
    "I'm here",
    'On my way',
    '5 minutes',
    'Wait please',
    'Thank you!',
  ];

  @override
  void initState() {
    super.initState();
    _typingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    unawaited(_connectWebSocket());
  }

  Future<void> _connectWebSocket() async {
    final rId = widget.roomId ?? 'test-room-123';
    final uId = widget.userId ?? 'driver-id-abc';

    final serviceUrl = EnvConfig.driverServiceUrl;
    final gatewayUrl = serviceUrl.replaceAll('8082', '8080');
    final wsScheme = gatewayUrl.startsWith('https') ? 'wss://' : 'ws://';
    final hostPort = gatewayUrl
        .replaceAll('https://', '')
        .replaceAll('http://', '');
    final wsUrl = '$wsScheme$hostPort/chat/ws?roomId=$rId&userId=$uId';

    try {
      final socket = await WebSocket.connect(wsUrl);
      if (!mounted) {
        socket.close();
        return;
      }
      _socket = socket;
      setState(() => _isConnected = true);

      socket.listen(
        (event) {
          final data = jsonDecode(event as String);
          if (data['type'] == 'history') {
            final list = data['messages'] as List;
            setState(() {
              _msgs.clear();
              for (final m in list) {
                final isPassenger = m['senderId'] != uId;
                _msgs.add(
                  _Msg(
                    m['text'] as String,
                    isPassenger,
                    DateTime.parse(m['createdAt'] as String).toLocal(),
                  ),
                );
              }
            });
            _scrollDown();
          } else if (data['type'] == 'message') {
            final isPassenger = data['senderId'] != uId;
            setState(() {
              _msgs.add(
                _Msg(
                  data['text'] as String,
                  isPassenger,
                  DateTime.parse(data['createdAt'] as String).toLocal(),
                ),
              );
            });
            _scrollDown();
          } else if (data['type'] == 'locked') {
            setState(() {
              _isChatRoomLocked = true;
              _lockWarningMessageText = data['reason'] as String? ?? 'This conversation is locked.';
            });
          }
        },
        onError: (_) {
          setState(() => _isConnected = false);
        },
        onDone: () {
          setState(() => _isConnected = false);
        },
      );
    } catch (_) {
      setState(() => _isConnected = false);
    }
  }

  @override
  void dispose() {
    if (_socket != null) {
      unawaited(_socket!.close());
    }
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _typingCtrl.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (_isChatRoomLocked) return;
    if (text.trim().isEmpty) return;
    if (_socket != null && _isConnected) {
      _socket!.add(jsonEncode({'text': text.trim()}));
      _msgCtrl.clear();
      _scrollDown();
    } else {
      _connectWebSocket();
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _fmtTime(DateTime dateTime) {
    final hourDisplay = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    return "$hourDisplay:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (!_isChatRoomLocked)
            TextButton(
              onPressed: _resolveChatRoom,
              child: const Text(
                'Resolve',
                style: TextStyle(
                  color: AppTheme.cancel,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrow_left,
            color: AppTheme.primaryColor,
          ),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.user,
                color: AppTheme.primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.peerName ?? 'Passenger',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _isConnected
                            ? AppTheme.complete
                            : AppTheme.cancel,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isConnected ? 'Connected' : 'Offline',
                      style: TextStyle(
                        color: _isConnected
                            ? AppTheme.complete
                            : AppTheme.cancel,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const Divider(height: 1, color: AppTheme.borderSide),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              itemCount: _msgs.length + (_passengerTyping ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _msgs.length && _passengerTyping) {
                  return _buildTyping();
                }
                return _buildBubble(_msgs[i]);
              },
            ),
          ),
          if (!_isChatRoomLocked)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: _quickReplies.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, itemIndex) => GestureDetector(
                  onTap: () => _send(_quickReplies[itemIndex]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.neutralColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderSide),
                    ),
                    child: Text(
                      _quickReplies[itemIndex],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border(
                  top: BorderSide(
                    color: AppTheme.borderSide.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.neutralColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.borderSide),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        readOnly: _isChatRoomLocked,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryColor,
                        ),
                        decoration: InputDecoration(
                          hintText: _isChatRoomLocked ? _lockWarningMessageText : 'Type a message...',
                          hintStyle: TextStyle(
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: _isChatRoomLocked ? null : _send,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _isChatRoomLocked ? null : () => _send(_msgCtrl.text),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isChatRoomLocked ? Colors.grey : AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.send,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_Msg m) {
    final isMe = !m.isPassenger;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LucideIcons.user,
                color: AppTheme.primaryColor,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryColor : AppTheme.neutralColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 6),
                  bottomRight: Radius.circular(isMe ? 6 : 20),
                ),
                border: isMe ? null : Border.all(color: AppTheme.borderSide),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    m.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.white : AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _fmtTime(m.time),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.6)
                              : AppTheme.primaryColor.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.check_check,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildTyping() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.user,
              color: AppTheme.primaryColor,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.neutralColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: AppTheme.borderSide),
            ),
            child: AnimatedBuilder(
              animation: _typingCtrl,
              builder: (ctx, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (dotIndex) {
                    final animationProgress = (_typingCtrl.value + dotIndex * 0.2) % 1.0;
                    return Container(
                      width: 7,
                      height: 7,
                      margin: EdgeInsets.only(right: dotIndex < 2 ? 4 : 0),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(
                          alpha: 0.2 + (animationProgress * 0.5),
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool isPassenger;
  final DateTime time;
  _Msg(this.text, this.isPassenger, this.time);
}

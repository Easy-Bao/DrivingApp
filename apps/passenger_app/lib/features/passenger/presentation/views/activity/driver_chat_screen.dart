import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:http/http.dart' as http;
import 'package:passenger_app/core/config/env_config.dart';
import 'package:passenger_app/core/services/passenger_api_service.dart';
import 'package:passenger_app/core/services/passenger_chat_service.dart';
import 'package:passenger_app/core/themes/app_themes.dart';

class DriverChatScreen extends StatefulWidget {
  final String? roomId;
  final String? userId;
  final String? token;
  final String? peerName;

  const DriverChatScreen({
    super.key,
    this.roomId,
    this.userId,
    this.token,
    this.peerName,
  });

  @override
  State<DriverChatScreen> createState() => _DriverChatScreenState();
}

class _DriverChatScreenState extends State<DriverChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  late AnimationController _typingCtrl;
  final bool _driverTyping = false;
  bool _isTripFinished = false;

  late PassengerChatService _chatService;
  StreamSubscription<void>? _chatUpdatesSubscription;

  Future<void> _checkTripStatus() async {
    final rId = widget.roomId ?? '';
    if (rId.isEmpty) return;
    try {
      final res = await PassengerApiService.getRideStatus(rId);
      if (res != null) {
        final status = res['status'] as String?;
        if (status == 'completed' || status == 'cancelled' || status == 'cancelled') {
          setState(() {
            _isTripFinished = true;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _resolveChatRoom() async {
    final chatRoomId = widget.roomId;
    if (chatRoomId == null || chatRoomId.isEmpty) {
      throw ArgumentError('Room ID cannot be empty');
    }
    try {
      final passengerServiceUrl = EnvConfig.passengerServiceUrl;
      final apiGatewayUrl = passengerServiceUrl.replaceAll('8081', '8080');
      final resolveEndpointUrl = '$apiGatewayUrl/chat/rooms/$chatRoomId/resolve';

      final resolveResponse = await http.post(
        Uri.parse(resolveEndpointUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (resolveResponse.statusCode == 200) {
        unawaited(_chatService.connectToChatRoom(
          roomId: chatRoomId,
          jsonWebToken: widget.token,
        ));
      }
    } catch (_) {}
  }

  final _quickReplies = [
    'Where are you?',
    "I'm at the pickup location",
    'Wait please',
    'Coming out now',
    'Thank you!',
  ];

  @override
  void initState() {
    super.initState();
    _typingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    unawaited(_typingCtrl.repeat(reverse: true));

    final currentRoomId = widget.roomId;
    final currentUserId = widget.userId;

    if (currentRoomId == null || currentRoomId.isEmpty) {
      throw ArgumentError('Room ID must be supplied and cannot be null or empty.');
    }
    if (currentUserId == null || currentUserId.isEmpty) {
      throw ArgumentError('User ID must be supplied and cannot be null or empty.');
    }

    _chatService = PassengerChatService(currentPassengerId: currentUserId);

    _chatUpdatesSubscription = _chatService.chatUpdatesStream.listen((_) {
      if (mounted) {
        setState(() {});
        _scrollDown();
      }
    });

    unawaited(_chatService.connectToChatRoom(
      roomId: currentRoomId,
      jsonWebToken: widget.token,
    ));

    unawaited(_checkTripStatus());
  }

  @override
  void dispose() {
    unawaited(_chatUpdatesSubscription?.cancel());
    unawaited(_chatService.disconnectChatRoom());
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _typingCtrl.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (_chatService.isRoomLocked) return;
    if (text.trim().isEmpty) return;

    if (_chatService.isConnectionActive) {
      _chatService.sendMessageToRoom(text);
      _msgCtrl.clear();
      _scrollDown();
    } else {
      final currentRoomId = widget.roomId;
      if (currentRoomId != null && currentRoomId.isNotEmpty) {
        unawaited(_chatService.connectToChatRoom(
          roomId: currentRoomId,
          jsonWebToken: widget.token,
        ));
      }
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        unawaited(
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),
        );
      }
    });
  }

  String _fmtTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return "$h:${t.minute.toString().padLeft(2, '0')} ${t.hour >= 12 ? 'PM' : 'AM'}";
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
          if (_isTripFinished && !_chatService.isRoomLocked)
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
                  widget.peerName ?? 'Driver',
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
                        color: _chatService.isConnectionActive ? AppTheme.complete : AppTheme.cancel,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _chatService.isConnectionActive ? 'Connected' : 'Offline',
                      style: TextStyle(
                        color: _chatService.isConnectionActive ? AppTheme.complete : AppTheme.cancel,
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
              itemCount: _chatService.chatHistoryMessages.length + (_driverTyping ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _chatService.chatHistoryMessages.length && _driverTyping) return _buildTyping();
                return _buildBubble(_chatService.chatHistoryMessages[i]);
              },
            ),
          ),
          if (!_chatService.isRoomLocked)
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
                        readOnly: _chatService.isRoomLocked,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryColor,
                        ),
                        decoration: InputDecoration(
                          hintText: _chatService.isRoomLocked ? _chatService.lockReasonMessage : 'Type a message...',
                          hintStyle: TextStyle(
                            color: AppTheme.primaryColor.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: _chatService.isRoomLocked ? null : _send,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _chatService.isRoomLocked ? null : () => _send(_msgCtrl.text),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _chatService.isRoomLocked ? Colors.grey : AppTheme.primaryColor,
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

  Widget _buildBubble(PassengerChatMessage m) {
    final isMe = !m.isDriver;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                        _fmtTime(m.createdAt),
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
                  children: List.generate(3, (i) {
                    final textTheme = (_typingCtrl.value + i * 0.2) % 1.0;
                    return Container(
                      width: 7,
                      height: 7,
                      margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(
                          alpha: 0.2 + (textTheme * 0.5),
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

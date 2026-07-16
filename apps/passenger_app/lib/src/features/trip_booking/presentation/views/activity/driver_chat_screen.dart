import 'dart:async';

import 'package:chat_service/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/di/service_locator.dart';
import 'package:passenger_app/src/core/network/api_endpoints.dart';
import 'package:passenger_app/src/core/services/passenger_api_service.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/chat/chat_cubit.dart';
import 'package:shared_ui/shared_ui.dart';

/// Screen enabling live chat communications between the passenger and their driver.
/// Uses [ChatCubit] to connect to WebSockets and sync messages.
class DriverChatScreen extends StatefulWidget {
  final String? roomId;
  final String? userId;
  final String? peerName;
  final String? token;

  const DriverChatScreen({
    super.key,
    this.roomId,
    this.userId,
    this.peerName,
    this.token,
  });

  @override
  State<DriverChatScreen> createState() => _DriverChatScreenState();
}

class _DriverChatScreenState extends State<DriverChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  late AnimationController _typingCtrl;
  final _driverTyping = false;
  bool _isTripFinished = false;

  late ChatCubit _chatCubit;

  Future<void> _checkTripStatus() async {
    final rId = widget.roomId ?? '';
    if (rId.isEmpty) return;
    try {
      final res = await getIt<PassengerApiService>().getRideStatus(rId);
      if (res != null) {
        final status = res['status'] as String?;
        if (status == 'completed' ||
            status == 'canceled' ||
            status == 'cancelled') {
          setState(() {
            _isTripFinished = true;
          });
        }
      }
    } catch (error) {
      debugPrint('Error checking trip status in chat screen: $error');
    }
  }

  Future<void> _resolveChatRoom() async {
    final chatRoomId = widget.roomId;
    final currentUserId = widget.userId;
    if (chatRoomId == null ||
        chatRoomId.isEmpty ||
        currentUserId == null ||
        currentUserId.isEmpty) {
      return;
    }
    final wsUri = ApiEndpoints.buildChatWebSocketUri(
      roomId: chatRoomId,
      userId: currentUserId,
      token: widget.token,
    );
    await _chatCubit.resolveChatRoom(chatRoomId, currentUserId, wsUri);
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
      throw ArgumentError(
        'Room ID must be supplied and cannot be null or empty.',
      );
    }
    if (currentUserId == null || currentUserId.isEmpty) {
      throw ArgumentError(
        'User ID must be supplied and cannot be null or empty.',
      );
    }

    _chatCubit = ChatCubit(currentUserId: currentUserId);
    final wsUri = ApiEndpoints.buildChatWebSocketUri(
      roomId: currentRoomId,
      userId: currentUserId,
      token: widget.token,
    );
    unawaited(_chatCubit.connect(currentRoomId, wsUri));
    unawaited(_checkTripStatus());
  }

  @override
  void dispose() {
    unawaited(_chatCubit.close());
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _typingCtrl.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    _chatCubit.sendMessage(text);
    _msgCtrl.clear();
    _scrollDown();
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

  String _fmtTime(DateTime dateTime) {
    final hourDisplay = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    return "$hourDisplay:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}";
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatCubit,
      child: BlocBuilder<ChatCubit, ChatState>(
        builder: (context, state) {
          final chatHistoryMessages = state.messages;

          return Scaffold(
            backgroundColor: AppTheme.surface,
            appBar: AppBar(
              backgroundColor: AppTheme.surface,
              elevation: 0,
              scrolledUnderElevation: 0,
              actions: [
                if (_isTripFinished && !state.isRoomLocked)
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
                              color: state.isConnected
                                  ? AppTheme.complete
                                  : AppTheme.cancel,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            state.isConnected ? 'Connected' : 'Offline',
                            style: TextStyle(
                              color: state.isConnected
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
                    itemCount:
                        chatHistoryMessages.length + (_driverTyping ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == chatHistoryMessages.length && _driverTyping) {
                        return _buildTyping();
                      }
                      return _buildBubble(chatHistoryMessages[i]);
                    },
                  ),
                ),
                if (!state.isRoomLocked)
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
                              readOnly: state.isRoomLocked,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.primaryColor,
                              ),
                              decoration: InputDecoration(
                                hintText: state.isRoomLocked
                                    ? state.lockReasonMessage
                                    : 'Type a message...',
                                hintStyle: TextStyle(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.4,
                                  ),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: (_) => _send(_msgCtrl.text),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              LucideIcons.send_horizontal,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () => _send(_msgCtrl.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    final isMe = msg.senderId == widget.userId;
    final timeStr = _fmtTime(msg.createdAt);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isMe ? AppTheme.primaryColor : AppTheme.neutralColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
              boxShadow: [
                if (isMe)
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                color: isMe ? Colors.white : AppTheme.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              timeStr,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTyping() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppTheme.neutralColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return FadeTransition(
              opacity: _typingCtrl,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.tertiaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

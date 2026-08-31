import 'package:chat/chat.dart';
import 'package:ride/ride.dart';
import 'dart:async';

import 'package:driver_app/src/core/constants/api_endpoints.dart';
import 'package:driver_app/src/features/chat/presentation/bloc/chat/chat_cubit.dart';
import 'package:driver_app/src/features/active_ride/domain/repositories/i_driver_ride_repository.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:design_system/design_system.dart';

class DriverChatPage extends StatefulWidget {
  final String? roomId;
  final String? userId;
  final String? peerId;
  final String? peerName;
  final IDriverRideRepository rideRepository;
  final ChatRepositoryFactory chatRepositoryFactory;

  const DriverChatPage({
    super.key,
    this.roomId,
    this.userId,
    this.peerId,
    this.peerName,
    required this.rideRepository,
    required this.chatRepositoryFactory,
  });

  @override
  State<DriverChatPage> createState() => _DriverChatPageState();
}

class _DriverChatPageState extends State<DriverChatPage> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  Timer? _typingStopTimer;
  bool _isTyping = false;
  bool _isTripFinished = false;

  late ChatCubit _chatCubit;

  Future<void> _checkTripStatus() async {
    final rId = widget.roomId ?? '';
    if (rId.isEmpty) return;
    try {
      RideSnapshot? ride;
      (await widget.rideRepository.fetchRide(
        rId,
      )).fold((_) {}, (value) => ride = value);
      if (ride?.isTerminal == true && mounted) {
        setState(() => _isTripFinished = true);
      }
    } catch (error) {
      debugPrint('Error checking trip status in driver chat: $error');
    }
  }

  Future<void> _resolveChatRoom() async {
    final chatRoomId = widget.roomId;
    if (chatRoomId == null || chatRoomId.isEmpty) {
      return;
    }
    await _chatCubit.resolveChatRoom(chatRoomId);
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

    _chatCubit = ChatCubit(
      chatRepository: widget.chatRepositoryFactory.create(
        currentUserId: currentUserId,
      ),
    );
    unawaited(_connectChat(currentRoomId, currentUserId));
    unawaited(_checkTripStatus());
  }

  Future<void> _connectChat(String roomId, String userId) async {
    final initialized = await _chatCubit.initializeChatRoom(roomId: roomId);
    if (!initialized || !mounted) return;
    final wsUri = ApiEndpoints.buildChatWebSocketUri(roomId: roomId);
    await _chatCubit.connectToChatRoom(roomId: roomId, wsUri: wsUri);
  }

  Future<void> _retryConnection() async {
    final roomId = widget.roomId;
    final userId = widget.userId;
    if (roomId == null || userId == null) return;
    await _connectChat(roomId, userId);
  }

  @override
  void dispose() {
    _typingStopTimer?.cancel();
    _isTyping = false;
    unawaited(_chatCubit.close());
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    await _stopTyping();
    final sent = await _chatCubit.sendMessage(text);
    if (!mounted) return;
    if (sent) {
      _msgCtrl.clear();
      _scrollDown();
    }
  }

  void _onDraftChanged(String value) {
    final canSendMessage =
        _chatCubit.state.isConnected && !_chatCubit.state.isRoomLocked;
    if (!canSendMessage || value.trim().isEmpty) {
      unawaited(_stopTyping());
      return;
    }

    if (!_isTyping) {
      _isTyping = true;
      unawaited(_chatCubit.updateTypingStatus(true));
    }
    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(const Duration(milliseconds: 1200), () {
      unawaited(_stopTyping());
    });
  }

  Future<void> _stopTyping() async {
    _typingStopTimer?.cancel();
    _typingStopTimer = null;
    if (!_isTyping) return;
    _isTyping = false;
    await _chatCubit.updateTypingStatus(false);
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
      child: BlocConsumer<ChatCubit, ChatState>(
        listenWhen: (previous, current) =>
            previous.messages != current.messages ||
            previous.isPeerTyping != current.isPeerTyping,
        listener: (_, state) {
          if (state.messages.isNotEmpty || state.isPeerTyping) _scrollDown();
        },
        builder: (context, state) {
          final chatHistoryMessages = state.messages;
          final statusLabel = state.isRoomLocked
              ? 'Resolved'
              : state.isConnecting
              ? 'Connecting...'
              : state.isConnected
              ? 'Connected'
              : 'Offline';
          final statusColor = state.isRoomLocked || state.isConnected
              ? context.semanticColors.success
              : context.colorScheme.error;
          final canSendMessage = state.isConnected && !state.isRoomLocked;

          return Scaffold(
            backgroundColor: context.colorScheme.surface,
            appBar: AppBar(
              backgroundColor: context.colorScheme.surface,
              elevation: 0,
              scrolledUnderElevation: 0,
              actions: [
                if (_isTripFinished && !state.isRoomLocked)
                  TextButton(
                    onPressed: _resolveChatRoom,
                    child: Text(
                      'Resolve',
                      style: TextStyle(
                        color: context.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
              leading: IconButton(
                style: IconButton.styleFrom(shape: const CircleBorder()),
                icon: Icon(
                  LucideIcons.arrow_left,
                  color: context.colorScheme.onSurface,
                ),
                onPressed: () => context.pop(),
              ),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.user,
                      color: context.colorScheme.onSurface,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.peerName ?? 'Passenger',
                        style: TextStyle(
                          color: context.colorScheme.onSurface,
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
                                  ? context.semanticColors.success
                                  : statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
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
                Divider(height: 1, color: context.colorScheme.outlineVariant),
                if (state.isRoomLocked || state.errorMessage != null)
                  _buildChatStatusBanner(state),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    itemCount:
                        chatHistoryMessages.length +
                        (state.isPeerTyping ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == chatHistoryMessages.length &&
                          state.isPeerTyping) {
                        return _buildTyping();
                      }
                      return _buildBubble(
                        chatHistoryMessages[i],
                        animate: identical(
                          state.lastDeliveredMessage,
                          chatHistoryMessages[i],
                        ),
                      );
                    },
                  ),
                ),
                if (canSendMessage)
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
                            color: context.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: context.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            _quickReplies[itemIndex],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.colorScheme.onSurface,
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
                      color: context.colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                          color: context.colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color:
                                  context.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: context.colorScheme.outlineVariant,
                              ),
                            ),
                            child: TextField(
                              controller: _msgCtrl,
                              readOnly: !canSendMessage,
                              textInputAction: TextInputAction.send,
                              style: TextStyle(
                                fontSize: 14,
                                color: context.colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                filled: false,
                                fillColor: context.colorScheme.surface
                                    .withValues(alpha: 0),
                                hintText: state.isRoomLocked
                                    ? state.lockReasonMessage
                                    : canSendMessage
                                    ? 'Type a message...'
                                    : 'Chat Is Unavailable Right Now.',
                                hintStyle: TextStyle(
                                  color: context.colorScheme.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                              ),
                              onChanged: _onDraftChanged,
                              onSubmitted: (_) =>
                                  unawaited(_send(_msgCtrl.text)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: !canSendMessage
                                ? context.colorScheme.surfaceContainerHighest
                                : context.colorScheme.onSurface,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              LucideIcons.send_horizontal,
                              size: 20,
                            ),
                            color: !canSendMessage
                                ? context.colorScheme.onSurfaceVariant
                                : context.colorScheme.onPrimary,
                            onPressed: !canSendMessage
                                ? null
                                : () => unawaited(_send(_msgCtrl.text)),
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

  Widget _buildChatStatusBanner(ChatState state) {
    final isResolved = state.isRoomLocked;
    final color = isResolved
        ? context.semanticColors.success
        : context.colorScheme.error;
    final message = isResolved
        ? state.lockReasonMessage
        : state.errorMessage ?? 'Chat Is Unavailable Right Now.';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isResolved ? LucideIcons.circle_check : LucideIcons.info,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isResolved ? 'Chat Resolved. $message' : message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!isResolved)
            TextButton(onPressed: _retryConnection, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg, {required bool animate}) {
    final isMe = msg.senderId == widget.userId;
    final timeStr = _fmtTime(msg.createdAt);

    return AppChatMessageTransition(
      key: ValueKey<String>('chat-message-${msg.identityKey}'),
      animate: animate,
      isOutgoing: isMe,
      child: Align(
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
                maxWidth: MediaQuery.sizeOf(context).width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isMe
                    ? context.colorScheme.primary
                    : context.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  if (isMe)
                    BoxShadow(
                      color: context.colorScheme.onSurface.withValues(
                        alpha: 0.15,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isMe
                      ? context.colorScheme.onPrimary
                      : context.colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    AppChatDeliveryIndicator(
                      isSending:
                          msg.deliveryStatus ==
                          ChatMessageDeliveryStatus.sending,
                      isDelivered:
                          msg.deliveryStatus ==
                          ChatMessageDeliveryStatus.delivered,
                      isFailed:
                          msg.deliveryStatus ==
                          ChatMessageDeliveryStatus.failed,
                      color: context.semanticColors.success,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTyping() {
    return AppChatTypingIndicator(
      bubbleColor: context.colorScheme.surfaceContainerHighest,
      dotColor: context.colorScheme.onSurfaceVariant,
      semanticLabel: '${widget.peerName ?? 'Passenger'} is typing',
    );
  }
}

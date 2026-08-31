import 'package:chat/chat.dart';
import 'package:ride/ride.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/constants/api_endpoints.dart';
import 'package:passenger_app/src/features/chat/presentation/bloc/chat/chat_cubit.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_track_repository.dart';
import 'package:design_system/design_system.dart';

class PassengerChatPage extends StatefulWidget {
  final String? roomId;
  final String? userId;
  final String? peerId;
  final String? peerName;
  final ITrackRepository trackRepository;
  final ChatRepositoryFactory chatRepositoryFactory;
  final String? token;

  const PassengerChatPage({
    super.key,
    this.roomId,
    this.userId,
    this.peerId,
    this.peerName,
    required this.trackRepository,
    required this.chatRepositoryFactory,
    this.token,
  });

  @override
  State<PassengerChatPage> createState() => _PassengerChatPageState();
}

class _PassengerChatPageState extends State<PassengerChatPage> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  Timer? _typingStopTimer;
  bool _isTyping = false;
  bool _isTripFinished = false;
  bool _isResolvingChat = false;

  late ChatCubit _chatCubit;

  Future<void> _checkTripStatus() async {
    final rId = widget.roomId ?? '';
    if (rId.isEmpty) return;
    try {
      RideSnapshot? ride;
      (await widget.trackRepository.fetchRide(
        rId,
      )).fold((_) {}, (value) => ride = value);
      if (ride?.isTerminal == true && mounted) {
        setState(() => _isTripFinished = true);
      }
    } catch (error) {
      debugPrint('Error checking trip status in chat screen: $error');
    }
  }

  Future<void> _resolveChatRoom() async {
    if (_isResolvingChat) return;

    final chatRoomId = widget.roomId;
    if (chatRoomId == null || chatRoomId.isEmpty) {
      return;
    }

    setState(() => _isResolvingChat = true);
    try {
      await _chatCubit.resolveChatRoom(chatRoomId);
    } finally {
      if (mounted) setState(() => _isResolvingChat = false);
    }
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
    await _chatCubit.connectToChatRoom(
      roomId: roomId,
      wsUri: wsUri,
      token: widget.token,
    );
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
                    onPressed: _isResolvingChat ? null : _resolveChatRoom,
                    child: Text(
                      _isResolvingChat ? 'Resolving...' : 'Resolve',
                      style: TextStyle(
                        color: _isResolvingChat
                            ? context.colorScheme.onSurfaceVariant
                            : context.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
              leading: Center(
                child: IconButton(
                  onPressed: () => context.pop(),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(shape: const CircleBorder()),
                  icon: Icon(
                    LucideIcons.arrow_left,
                    color: context.colorScheme.onSurface,
                    size: 20,
                  ),
                ),
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
                        widget.peerName ?? 'Driver',
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
                              color: statusColor,
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
                if (!state.isRoomLocked &&
                    state.errorMessage != null &&
                    chatHistoryMessages.isNotEmpty)
                  _buildErrorBanner(state),
                if (state.isRoomLocked && chatHistoryMessages.isNotEmpty)
                  _buildResolvedBanner(state),
                Expanded(
                  child: chatHistoryMessages.isEmpty && !state.isPeerTyping
                      ? _buildEmptyState(state)
                      : ListView.builder(
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
                                    : state.isConnected
                                    ? 'Type a message...'
                                    : 'Reconnect to send a message',
                                hintStyle: TextStyle(
                                  color: context.colorScheme.onSurface
                                      .withValues(alpha: 0.4),
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
                            color: canSendMessage
                                ? context.colorScheme.onSurface
                                : context.colorScheme.surfaceContainerHighest,
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

  Widget _buildEmptyState(ChatState state) {
    if (state.isRoomLocked) {
      return _buildResolvedEmptyState(state);
    }
    if (state.isConnecting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.message_circle_off,
                color: context.colorScheme.error,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _retryConnection,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Text(
        'No messages yet. Start the conversation.',
        style: TextStyle(color: context.colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildResolvedBanner(ChatState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colorScheme.secondaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.semanticColors.success.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.circle_check,
            color: context.semanticColors.success,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chat resolved',
                  style: TextStyle(
                    color: context.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  state.lockReasonMessage,
                  style: TextStyle(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolvedEmptyState(ChatState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.circle_check,
              color: context.semanticColors.success,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              'Chat resolved',
              style: TextStyle(
                color: context.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              state.lockReasonMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(ChatState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.colorScheme.error.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.circle_alert,
            color: context.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              state.errorMessage!,
              style: TextStyle(
                color: context.colorScheme.onSurface,
                fontSize: 12,
              ),
            ),
          ),
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
                    ? context.colorScheme.onSurface
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
                      ? context.colorScheme.surface
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
      semanticLabel: '${widget.peerName ?? 'Driver'} is typing',
    );
  }
}

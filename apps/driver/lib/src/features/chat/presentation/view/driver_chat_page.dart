import 'package:driver/src/features/chat/chat.dart';

import 'dart:async';

import 'package:driver/src/infrastructure/config/driver_env_config.dart';
import 'package:driver/src/features/chat/presentation/bloc/chat/chat_cubit.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:design_system/design_system.dart';

class const ChatPage({
  super.key,
  this.roomId,
  this.userId,
  this.peerId,
  this.peerName,
  required this.chatRepositoryFactory,
}) extends StatefulWidget {
  final String? roomId;
  final String? userId;
  final String? peerId;
  final String? peerName;
  final ChatRepositoryFactory chatRepositoryFactory;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingStopTimer;
  bool _isTyping = false;
  late ChatCubit _chatCubit;

  static const _quickReplies = [
    'I have arrived',
    'In traffic',
    'At pickup point',
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
      currentUserId: currentUserId,
      chatRepository: widget.chatRepositoryFactory.create(
        currentUserId: currentUserId,
      ),
    );
    unawaited(_connectChat(currentRoomId, currentUserId));
  }

  Future<void> _connectChat(String roomId, String userId) async {
    final initialized = await _chatCubit.initializeChatRoom(roomId: roomId);
    if (!initialized || !mounted) return;
    final realtimeUri = EnvConfig.webSocketBaseUri.replace(
      path: '/api/v1/chat/ws',
      queryParameters: {'roomId': roomId},
    );
    await _chatCubit.connectToChatRoom(roomId: roomId, chatUri: realtimeUri);
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    await _stopTyping();
    final sent = await _chatCubit.sendMessage(text);
    if (!mounted) return;
    if (sent) {
      _messageController.clear();
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
      if (_scrollController.hasClients) {
        unawaited(
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),
        );
      }
    });
  }

  String _formatMessageTime(DateTime dateTime) {
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
          final canSendMessage = state.isConnected && !state.isRoomLocked;

          return Scaffold(
            backgroundColor: context.colorScheme.surface,
            appBar: AppBar(
              backgroundColor: context.colorScheme.surface,
              scrolledUnderElevation: 0,
              leading: IconButton(
                style: IconButton.styleFrom(shape: const CircleBorder()),
                icon: Icon(
                  LucideIcons.arrow_left,
                  color: context.colorScheme.onSurface,
                ),
                onPressed: () => context.pop(),
              ),
              title: Text(
                widget.peerName ?? 'Passenger',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ),
            body: Column(
              children: [
                Divider(height: 1, color: context.colorScheme.outlineVariant),
                if (chatHistoryMessages.isNotEmpty &&
                    (state.isRoomLocked ||
                        (state.errorMessage != null &&
                            !AppNetworkStatusScope.isUnavailableOf(context))))
                  _buildChatStatusBanner(state),
                Expanded(
                  child: chatHistoryMessages.isEmpty && !state.isPeerTyping
                      ? _buildEmptyState(state)
                      : ListView.builder(
                          controller: _scrollController,
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
                if (canSendMessage && state.errorMessage == null)
                  SizedBox(
                    height: AppSize.minimumTouchTarget,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _quickReplies.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, itemIndex) => Semantics(
                        button: true,
                        label: 'Send quick reply ${_quickReplies[itemIndex]}',
                        child: Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            onTap: () => _send(_quickReplies[itemIndex]),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    context.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
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
                    ),
                  ),
                const SizedBox(height: 8),
                if (state.isRoomLocked)
                  _buildEndedFooter(context)
                else
                  SafeArea(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      decoration: BoxDecoration(
                        color: context.colorScheme.surface,
                        border: Border(
                          top: BorderSide(
                            color: context.colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    context.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                                border: Border.all(
                                  color: context.colorScheme.outlineVariant,
                                ),
                              ),
                              child: TextField(
                                controller: _messageController,
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
                                    unawaited(_send(_messageController.text)),
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
                              constraints: const BoxConstraints(
                                minWidth: AppSize.minimumTouchTarget,
                                minHeight: AppSize.minimumTouchTarget,
                              ),
                              icon: const Icon(
                                LucideIcons.send_horizontal,
                                size: 20,
                              ),
                              color: !canSendMessage
                                  ? context.colorScheme.onSurfaceVariant
                                  : context.colorScheme.onPrimary,
                              onPressed: !canSendMessage
                                  ? null
                                  : () => unawaited(
                                      _send(_messageController.text),
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
        },
      ),
    );
  }

  Widget _buildEndedFooter(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: context.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Text(
          'This conversation has ended',
          textAlign: TextAlign.center,
          style: context.textStyles.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ChatState state) {
    if (state.isRoomLocked) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Chat is closed for this trip',
                style: context.textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Messages are available during active trips and up to 24 hours after completion.',
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (state.isConnecting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null &&
        !AppNetworkStatusScope.isUnavailableOf(context)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.colorScheme.onSurfaceVariant),
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
        'No messages yet',
        style: TextStyle(color: context.colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildChatStatusBanner(ChatState state) {
    if (state.isRoomLocked) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat is closed for this trip',
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Messages are available during active trips and up to 24 hours after completion.',
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AppErrorBanner(
        message: state.errorMessage ?? 'Chat is unavailable right now.',
        onRetry: _retryConnection,
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg, {required bool animate}) {
    final isMe = msg.senderId == widget.userId;
    final formattedTime = _formatMessageTime(msg.createdAt);

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
                  topLeft: const Radius.circular(AppRadius.lg),
                  topRight: const Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
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
                    formattedTime,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
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

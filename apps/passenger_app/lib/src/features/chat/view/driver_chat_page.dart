import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/constants/api_endpoints.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/chat/bloc/chat/chat_cubit.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_track_repository.dart';
import 'package:shared_core/shared_core.dart';

class DriverChatPage extends StatefulWidget {
  final String? roomId;
  final String? userId;
  final String? peerId;
  final String? peerName;
  final ITrackRepository trackRepository;
  final IChatRepositoryFactory chatRepositoryFactory;
  final String? token;

  const DriverChatPage({
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
  State<DriverChatPage> createState() => _DriverChatPageState();
}

class _DriverChatPageState extends State<DriverChatPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  late AnimationController _typingCtrl;
  final _driverTyping = false;
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
    unawaited(_chatCubit.close());
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _typingCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    final sent = await _chatCubit.sendMessage(text);
    if (!mounted) return;
    if (sent) {
      _msgCtrl.clear();
      _scrollDown();
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
            previous.messages != current.messages,
        listener: (_, state) {
          if (state.messages.isNotEmpty) _scrollDown();
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
              ? AppTheme.complete
              : AppTheme.cancel;
          final canSendMessage = state.isConnected && !state.isRoomLocked;

          return Scaffold(
            backgroundColor: AppTheme.surface,
            appBar: AppBar(
              backgroundColor: AppTheme.surface,
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
                            ? AppTheme.primaryColor.withValues(alpha: 0.4)
                            : AppTheme.cancel,
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
                  icon: const Icon(
                    LucideIcons.arrow_left,
                    color: AppTheme.primaryColor,
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
                const Divider(height: 1, color: AppTheme.borderSide),
                if (!state.isRoomLocked &&
                    state.errorMessage != null &&
                    chatHistoryMessages.isNotEmpty)
                  _buildErrorBanner(state),
                if (state.isRoomLocked && chatHistoryMessages.isNotEmpty)
                  _buildResolvedBanner(state),
                Expanded(
                  child: chatHistoryMessages.isEmpty
                      ? _buildEmptyState(state)
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.all(16),
                          physics: const BouncingScrollPhysics(),
                          itemCount:
                              chatHistoryMessages.length +
                              (_driverTyping ? 1 : 0),
                          itemBuilder: (ctx, i) {
                            if (i == chatHistoryMessages.length &&
                                _driverTyping) {
                              return _buildTyping();
                            }
                            return _buildBubble(chatHistoryMessages[i]);
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
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.neutralColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppTheme.borderSide),
                            ),
                            child: TextField(
                              controller: _msgCtrl,
                              readOnly: !canSendMessage,
                              textInputAction: TextInputAction.send,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.primaryColor,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                filled: false,
                                fillColor: AppTheme.surface.withValues(
                                  alpha: 0,
                                ),
                                hintText: state.isRoomLocked
                                    ? state.lockReasonMessage
                                    : state.isConnected
                                    ? 'Type a message...'
                                    : 'Reconnect to send a message',
                                hintStyle: TextStyle(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.4,
                                  ),
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
                              onSubmitted: (_) =>
                                  unawaited(_send(_msgCtrl.text)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: canSendMessage
                                ? AppTheme.primaryColor
                                : AppTheme.neutralColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              LucideIcons.send_horizontal,
                              size: 20,
                            ),
                            color: !canSendMessage
                                ? AppTheme.tertiaryColor
                                : AppTheme.activeControlForeground,
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
              const Icon(
                LucideIcons.message_circle_off,
                color: AppTheme.cancel,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.primaryColor.withValues(alpha: 0.65),
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
        style: TextStyle(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
      ),
    );
  }

  Widget _buildResolvedBanner(ChatState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.complete.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.circle_check,
            color: AppTheme.complete,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chat resolved',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  state.lockReasonMessage,
                  style: TextStyle(
                    color: AppTheme.primaryColor.withValues(alpha: 0.6),
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
            const Icon(
              LucideIcons.circle_check,
              color: AppTheme.complete,
              size: 36,
            ),
            const SizedBox(height: 12),
            const Text(
              'Chat resolved',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              state.lockReasonMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.primaryColor.withValues(alpha: 0.6),
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
        color: AppTheme.cancel.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cancel.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.circle_alert,
            color: AppTheme.cancel,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              state.errorMessage!,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(onPressed: _retryConnection, child: const Text('Retry')),
        ],
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
              maxWidth: MediaQuery.sizeOf(context).width * 0.75,
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
                color: isMe ? AppTheme.surface : AppTheme.primaryColor,
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

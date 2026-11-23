import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/core/config/env_config.dart';
import 'package:passenger/src/features/chat/chat.dart';
import 'package:passenger/src/features/chat/presentation/bloc/chat_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    this.roomId,
    this.userId,
    this.peerId,
    this.peerName,
    required this.chatRepositoryFactory,
    this.token,
  });
  final String? roomId;
  final String? userId;
  final String? peerId;
  final String? peerName;
  final ChatRepositoryFactory chatRepositoryFactory;
  final String? token;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  bool _isPickingImage = false;
  bool _isCalling = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingStopTimer;
  bool _isTyping = false;
  late ChatCubit _chatCubit;

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
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_markVisibleMessagesRead);
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
    await _chatCubit.connectToChatRoom(
      roomId: roomId,
      chatUri: realtimeUri,
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
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_markVisibleMessagesRead);
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _markVisibleMessagesRead();
  }

  void _markVisibleMessagesRead() {
    if (!mounted ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
        ModalRoute.of(context)?.isCurrent != true ||
        !_scrollController.hasClients ||
        _scrollController.position.extentAfter > 1) {
      return;
    }
    unawaited(_chatCubit.markVisibleMessagesRead());
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage || _chatCubit.state.isSendingImage) return;
    _isPickingImage = true;
    try {
      final picture = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (picture == null || !mounted) return;
      if (await picture.length() > 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose a picture up to 5 MB.')),
        );
        return;
      }
      final bytes = await picture.readAsBytes();
      if (!mounted) return;
      await _stopTyping();
      if (!mounted) return;
      await _chatCubit.sendImage(bytes);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to select picture. Please try again.'),
          ),
        );
      }
    } finally {
      _isPickingImage = false;
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          ModalRoute.of(context)?.isCurrent == true &&
          _scrollController.hasClients) {
        unawaited(
          _scrollController
              .animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              )
              .then((_) => _markVisibleMessagesRead()),
        );
      }
    });
  }

  String _formatMessageTime(DateTime dateTime) {
    final hourDisplay = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    return "$hourDisplay:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}";
  }

  Future<void> _callPeer() async {
    if (_isCalling) return;
    setState(() => _isCalling = true);
    String? error;
    try {
      final result = await _chatCubit.resolveCallPhone();
      if (!mounted) return;
      final phone = result.fold((failure) {
        error = failure.message;
        return null;
      }, (phone) => phone);
      if (phone != null && !await launchUrl(Uri(scheme: 'tel', path: phone))) {
        error = 'Unable to open the phone dialer. Please try again.';
      }
    } catch (_) {
      error = 'Unable to start the call. Please try again.';
    } finally {
      if (mounted) {
        setState(() => _isCalling = false);
        if (error != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error!)));
        }
      }
    }
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
          final colors = context.colorScheme;
          final hairline = colors.outlineVariant.withValues(alpha: 0.7);
          final chatHistoryMessages = state.messages;
          final canSendMessage = state.isConnected && !state.isRoomLocked;

          return Scaffold(
            backgroundColor: context.canvasColor,
            appBar: AppBar(
              backgroundColor: context.canvasColor,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              leading: Center(
                child: IconButton(
                  onPressed: () => context.pop(),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  padding: EdgeInsets.zero,
                  style:
                      IconButton.styleFrom(
                        foregroundColor: colors.onSurface,
                        shape: const CircleBorder(),
                        enableFeedback: false,
                        splashFactory: NoSplash.splashFactory,
                      ).copyWith(
                        overlayColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.focused)
                              ? colors.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                        ),
                      ),
                  icon: Icon(
                    LucideIcons.arrow_left,
                    color: colors.onSurface,
                    size: 19,
                  ),
                ),
              ),
              actions: [
                if (state.peer?.canCall == true && !state.isAccessDenied)
                  IconButton(
                    tooltip: 'Call driver',
                    onPressed: _isCalling ? null : _callPeer,
                    style:
                        IconButton.styleFrom(
                          foregroundColor: colors.onSurface,
                          enableFeedback: false,
                          splashFactory: NoSplash.splashFactory,
                        ).copyWith(
                          overlayColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.focused)
                                ? colors.primary.withValues(alpha: 0.12)
                                : Colors.transparent,
                          ),
                        ),
                    icon: const Icon(LucideIcons.phone, size: 19),
                  ),
              ],
              title: ChatPeerHeader(
                name: state.peer?.name.isNotEmpty == true
                    ? state.peer!.name
                    : widget.peerName ?? 'Driver',
                subtitle: state.peer?.vehicleLabel ?? '',
              ),
            ),
            body: Column(
              children: [
                Divider(height: 1, color: hairline),
                if (state.isRoomLocked && chatHistoryMessages.isNotEmpty)
                  _buildClosedBanner(),
                if (state.errorMessage != null &&
                    !state.isAccessDenied &&
                    !AppNetworkStatusScope.isUnavailableOf(context) &&
                    chatHistoryMessages.isNotEmpty)
                  _buildErrorBanner(state),
                Expanded(
                  child: chatHistoryMessages.isEmpty && !state.isPeerTyping
                      ? _buildEmptyState(state)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          physics: const BouncingScrollPhysics(),
                          itemCount:
                              chatHistoryMessages.length +
                              (state.isPeerTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == chatHistoryMessages.length &&
                                state.isPeerTyping) {
                              return _buildTyping();
                            }
                            return _buildBubble(
                              chatHistoryMessages[index],
                              animate: identical(
                                state.lastDeliveredMessage,
                                chatHistoryMessages[index],
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _quickReplies.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, itemIndex) => Semantics(
                        button: true,
                        label: 'Send quick reply ${_quickReplies[itemIndex]}',
                        child: Center(
                          child: Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              enableFeedback: false,
                              splashFactory: NoSplash.splashFactory,
                              overlayColor: WidgetStateProperty.resolveWith(
                                (states) => states.contains(WidgetState.focused)
                                    ? colors.primary.withValues(alpha: 0.12)
                                    : Colors.transparent,
                              ),
                              onTap: () => _send(_quickReplies[itemIndex]),
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: 40,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                  border: Border.all(
                                    color: colors.outlineVariant,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _quickReplies[itemIndex],
                                  style: context.textStyles.labelMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colors.onSurface,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                if (state.isRoomLocked)
                  _buildEndedFooter(context)
                else
                  SafeArea(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLowest,
                        border: Border(top: BorderSide(color: hairline)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Take photo',
                            onPressed: canSendMessage && !state.isSendingImage
                                ? () => _pickImage(ImageSource.camera)
                                : null,
                            style:
                                IconButton.styleFrom(
                                  foregroundColor: colors.onSurfaceVariant,
                                  enableFeedback: false,
                                  splashFactory: NoSplash.splashFactory,
                                ).copyWith(
                                  overlayColor: WidgetStateProperty.resolveWith(
                                    (states) =>
                                        states.contains(WidgetState.focused)
                                        ? colors.primary.withValues(alpha: 0.12)
                                        : Colors.transparent,
                                  ),
                                ),
                            icon: const Icon(LucideIcons.camera, size: 19),
                          ),
                          IconButton(
                            tooltip: 'Attach photo file',
                            onPressed: canSendMessage && !state.isSendingImage
                                ? () => _pickImage(ImageSource.gallery)
                                : null,
                            style:
                                IconButton.styleFrom(
                                  foregroundColor: colors.onSurfaceVariant,
                                  enableFeedback: false,
                                  splashFactory: NoSplash.splashFactory,
                                ).copyWith(
                                  overlayColor: WidgetStateProperty.resolveWith(
                                    (states) =>
                                        states.contains(WidgetState.focused)
                                        ? colors.primary.withValues(alpha: 0.12)
                                        : Colors.transparent,
                                  ),
                                ),
                            icon: state.isSendingImage
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.onSurface,
                                    ),
                                  )
                                : const Icon(LucideIcons.paperclip, size: 19),
                          ),
                          Expanded(
                            child: Container(
                              height: 46,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              decoration: BoxDecoration(
                                color: context.canvasColor,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                border: Border.all(
                                  color: colors.outlineVariant,
                                ),
                              ),
                              child: TextField(
                                controller: _messageController,
                                readOnly: !canSendMessage,
                                textInputAction: TextInputAction.send,
                                style: context.textStyles.bodyMedium?.copyWith(
                                  color: colors.onSurface,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: false,
                                  fillColor: Colors.transparent,
                                  hintText: state.isRoomLocked
                                      ? state.lockReasonMessage
                                      : state.isConnected
                                      ? 'Type a message...'
                                      : 'Reconnect to send a message',
                                  hintStyle: context.textStyles.bodyMedium
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
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
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            decoration: BoxDecoration(
                              color: canSendMessage
                                  ? colors.primary
                                  : colors.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                LucideIcons.send_horizontal,
                                size: 18,
                              ),
                              style:
                                  IconButton.styleFrom(
                                    enableFeedback: false,
                                    splashFactory: NoSplash.splashFactory,
                                  ).copyWith(
                                    overlayColor:
                                        WidgetStateProperty.resolveWith(
                                          (states) =>
                                              states.contains(
                                                WidgetState.focused,
                                              )
                                              ? colors.onPrimary.withValues(
                                                  alpha: 0.16,
                                                )
                                              : Colors.transparent,
                                        ),
                                  ),
                              constraints: const BoxConstraints(
                                minWidth: AppSize.minimumTouchTarget,
                                minHeight: AppSize.minimumTouchTarget,
                              ),
                              color: !canSendMessage
                                  ? colors.onSurfaceVariant
                                  : colors.onPrimary,
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
    final colors = context.colorScheme;
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          border: Border(
            top: BorderSide(
              color: colors.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
        child: Text(
          'This conversation has ended',
          textAlign: TextAlign.center,
          style: context.textStyles.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ChatState state) {
    final colors = context.colorScheme;
    if (state.isConnecting || state.isLoadingHistory) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colors.onSurface,
        ),
      );
    }
    if (!state.isAccessDenied &&
        state.errorMessage != null &&
        !AppNetworkStatusScope.isUnavailableOf(context)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: _retryConnection,
                style:
                    OutlinedButton.styleFrom(
                      backgroundColor: colors.surfaceContainerLowest,
                      foregroundColor: colors.onSurface,
                      side: BorderSide(color: colors.outlineVariant),
                      enableFeedback: false,
                      splashFactory: NoSplash.splashFactory,
                      minimumSize: const Size(0, AppSize.minimumTouchTarget),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.focused)
                            ? colors.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                      ),
                    ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Text(
        'No message yet',
        style: context.textStyles.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildClosedBanner() {
    final colors = context.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chat is closed for this trip',
            style: context.textStyles.bodyMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'This conversation has ended. Previous messages remain available to view.',
            style: context.textStyles.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(ChatState state) {
    if (AppNetworkStatusScope.isUnavailableOf(context)) {
      return const SizedBox.shrink();
    }
    final colors = context.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              state.errorMessage!,
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.onSurface,
              ),
            ),
          ),
          TextButton(
            onPressed: _retryConnection,
            style:
                TextButton.styleFrom(
                  foregroundColor: colors.onSurface,
                  enableFeedback: false,
                  splashFactory: NoSplash.splashFactory,
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.focused)
                        ? colors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                  ),
                ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessage message, {required bool animate}) {
    final colors = context.colorScheme;
    final isMe = message.senderId == widget.userId;
    final formattedTime = _formatMessageTime(message.createdAt);

    return AppChatMessageTransition(
      key: ValueKey<String>('chat-message-${message.identityKey}'),
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
              padding: message.hasImage
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.75,
              ),
              decoration: message.hasImage
                  ? null
                  : BoxDecoration(
                      color: isMe
                          ? colors.primary
                          : colors.surfaceContainerLowest,
                      border: isMe
                          ? null
                          : Border.all(color: colors.outlineVariant),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(AppRadius.lg),
                        topRight: const Radius.circular(AppRadius.lg),
                        bottomLeft: Radius.circular(isMe ? AppRadius.lg : 4),
                        bottomRight: Radius.circular(isMe ? 4 : AppRadius.lg),
                      ),
                    ),
              child: message.hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: ChatPicture(
                        load: () => _chatCubit.loadImage(message.id),
                      ),
                    )
                  : Text(
                      message.text,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: isMe ? colors.onPrimary : colors.onSurface,
                        height: 1.35,
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
                    style: context.textStyles.labelSmall?.tabular.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    AppChatDeliveryIndicator(
                      isSending:
                          message.deliveryStatus ==
                          ChatMessageDeliveryStatus.sending,
                      isDelivered:
                          message.deliveryStatus ==
                          ChatMessageDeliveryStatus.seen,
                      isFailed:
                          message.deliveryStatus ==
                          ChatMessageDeliveryStatus.failed,
                      color: context.semanticColors.success,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildTyping() {
    return AppChatTypingIndicator(
      bubbleColor: context.colorScheme.surfaceContainerLowest,
      dotColor: context.colorScheme.onSurfaceVariant,
      semanticLabel: '${widget.peerName ?? 'Driver'} is typing',
    );
  }
}

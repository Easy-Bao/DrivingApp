import 'dart:async';

import 'package:chat/src/data/repositories/chat_repository_factory.dart';
import 'package:chat/src/domain/entities/chat_message.dart';
import 'package:chat/src/presentation/bloc/chat_cubit.dart';
import 'package:chat/src/presentation/bloc/chat_state.dart';
import 'package:chat/src/presentation/chat_page_config.dart';
import 'package:chat/src/presentation/widgets/chat_composer.dart';
import 'package:chat/src/presentation/widgets/chat_message_bubble.dart';
import 'package:chat/src/presentation/widgets/chat_quick_replies.dart';
import 'package:chat/src/presentation/widgets/chat_status_widgets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ChatWebSocketUriBuilder = Uri Function(String roomId);

class const ChatPage({
  super.key,
  required this.roomId,
  required this.userId,
  required this.chatRepositoryFactory,
  required this.chatUriBuilder,
  required this.config,
  this.peerId,
  this.peerName,
  this.token,
  this.onBack,
}) extends StatefulWidget {
  final String roomId;
  final String userId;
  final String? peerId;
  final String? peerName;
  final String? token;
  final ChatRepositoryFactory chatRepositoryFactory;
  final ChatWebSocketUriBuilder chatUriBuilder;
  final ChatPageConfig config;
  final VoidCallback? onBack;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  static const _maxImageBytes = 5 * 1024 * 1024;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatCubit _chatCubit;
  Timer? _typingStopTimer;
  bool _isTyping = false;
  bool _isPickingImage = false;
  bool _isCalling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_markVisibleMessagesRead);

    final currentRoomId = widget.roomId.trim();
    final currentUserId = widget.userId.trim();
    if (currentRoomId.isEmpty) {
      throw ArgumentError('Room ID must be supplied and cannot be empty.');
    }
    if (currentUserId.isEmpty) {
      throw ArgumentError('User ID must be supplied and cannot be empty.');
    }

    _chatCubit = ChatCubit(
      currentUserId: currentUserId,
      chatRepository: widget.chatRepositoryFactory.create(
        currentUserId: currentUserId,
      ),
    );
    unawaited(_connectChat(currentRoomId));
  }

  Future<void> _connectChat(String roomId) async {
    final initialized = await _chatCubit.initializeChatRoom(roomId: roomId);
    if (!initialized || !mounted) return;
    final realtimeUri = widget.chatUriBuilder(roomId);
    await _chatCubit.connectToChatRoom(
      roomId: roomId,
      chatUri: realtimeUri,
      token: widget.token,
    );
  }

  Future<void> _retryConnection() => _connectChat(widget.roomId.trim());

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

  Future<void> _retryMessage(ChatMessage message) async {
    final resent = await _chatCubit.retryMessage(message);
    if (mounted && resent) _scrollDown();
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
      if (await picture.length() > _maxImageBytes) {
        if (!mounted) return;
        AppSnackBar.show(
          context,
          'Choose a picture up to 5 MB.',
          isError: true,
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
        AppSnackBar.show(
          context,
          'Unable to select picture. Please try again.',
          isError: true,
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
        final disableAnimations =
            MediaQuery.maybeDisableAnimationsOf(context) ?? false;
        final extent = _scrollController.position.maxScrollExtent;
        if (disableAnimations) {
          _scrollController.jumpTo(extent);
          _markVisibleMessagesRead();
          return;
        }
        unawaited(
          _scrollController
              .animateTo(
                extent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              )
              .then((_) => _markVisibleMessagesRead()),
        );
      }
    });
  }

  Future<void> _callPeer() async {
    if (_isCalling) return;
    setState(() => _isCalling = true);
    String? error;
    try {
      final result = await _chatCubit.resolveCallPhone();
      if (!mounted) return;
      final phone = switch (result) {
        Err(:final failure) => () {
          error = failure.message;
          return null;
        }(),
        Ok(:final value) => value,
      };
      if (phone != null && !await launchUrl(Uri(scheme: 'tel', path: phone))) {
        error = 'Unable to open the phone dialer. Please try again.';
      }
    } catch (_) {
      error = 'Unable to start the call. Please try again.';
    } finally {
      if (mounted) {
        setState(() => _isCalling = false);
        if (error case final errorMessage?) {
          AppSnackBar.show(context, errorMessage, isError: true);
        }
      }
    }
  }

  void _handleBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    unawaited(Navigator.of(context).maybePop());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final hairline = colors.outlineVariant.withValues(alpha: 0.7);

    return BlocProvider<ChatCubit>.value(
      value: _chatCubit,
      child: BlocConsumer<ChatCubit, ChatState>(
        listenWhen: (previous, current) =>
            previous.messages != current.messages ||
            previous.isPeerTyping != current.isPeerTyping,
        listener: (_, state) {
          if (state.messages.isNotEmpty || state.isPeerTyping) _scrollDown();
        },
        builder: (context, state) {
          final messages = state.messages;
          final canSendMessage = state.isConnected && !state.isRoomLocked;
          final peerName = state.peer?.name.isNotEmpty == true
              ? state.peer!.name
              : widget.peerName ?? widget.config.defaultPeerName;

          return Scaffold(
            backgroundColor: context.canvasColor,
            appBar: AppBar(
              backgroundColor: context.canvasColor,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              leading: Center(
                child: IconButton(
                  onPressed: _handleBack,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  padding: EdgeInsets.zero,
                  style: AppQuietInteraction.iconButtonStyle(
                    colors,
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
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
                    tooltip: widget.config.callTooltip,
                    onPressed: _isCalling ? null : _callPeer,
                    style: AppQuietInteraction.iconButtonStyle(colors),
                    icon: const Icon(LucideIcons.phone, size: 19),
                  ),
              ],
              title: ChatPeerHeader(
                name: peerName,
                subtitle: state.peer?.vehicleLabel ?? '',
              ),
            ),
            body: Column(
              children: [
                Divider(height: 1, color: hairline),
                if (state.isRoomLocked && messages.isNotEmpty)
                  const ChatClosedBanner(),
                if (state.errorMessage != null &&
                    !state.isAccessDenied &&
                    !state.isRoomLocked &&
                    messages.isNotEmpty)
                  ChatConnectionErrorBanner(
                    message: state.errorMessage!,
                    onRetry: () => unawaited(_retryConnection()),
                  ),
                Expanded(
                  child: messages.isEmpty && !state.isPeerTyping
                      ? ChatEmptyState(
                          state: state,
                          onRetry: () => unawaited(_retryConnection()),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          physics: const BouncingScrollPhysics(),
                          itemCount:
                              messages.length + (state.isPeerTyping ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == messages.length &&
                                state.isPeerTyping) {
                              return AppChatTypingIndicator(
                                bubbleColor: colors.surfaceContainerHighest,
                                dotColor: colors.onSurfaceVariant,
                                semanticLabel: '$peerName is typing',
                              );
                            }
                            final message = messages[index];
                            return ChatMessageBubble(
                              message: message,
                              isOutgoing: message.senderId == widget.userId,
                              animate: identical(
                                state.lastDeliveredMessage,
                                message,
                              ),
                              onLoadImage: _chatCubit.loadImage,
                              onRetry: canSendMessage
                                  ? () => unawaited(_retryMessage(message))
                                  : null,
                            );
                          },
                        ),
                ),
                if (canSendMessage && state.errorMessage == null)
                  ChatQuickReplies(
                    replies: widget.config.quickReplies,
                    onSelected: (reply) => unawaited(_send(reply)),
                  ),
                const SizedBox(height: AppSpacing.sm),
                if (state.isRoomLocked)
                  const ChatEndedFooter()
                else
                  ChatComposer(
                    controller: _messageController,
                    canSendMessage: canSendMessage,
                    isConnected: state.isConnected,
                    isRoomLocked: state.isRoomLocked,
                    isSendingImage: state.isSendingImage,
                    lockReasonMessage: state.lockReasonMessage,
                    onChanged: _onDraftChanged,
                    onSend: () => unawaited(_send(_messageController.text)),
                    onCameraPressed: () =>
                        unawaited(_pickImage(ImageSource.camera)),
                    onGalleryPressed: () =>
                        unawaited(_pickImage(ImageSource.gallery)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

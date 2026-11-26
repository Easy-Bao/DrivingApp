import 'dart:typed_data';

import 'package:chat/src/domain/entities/chat_message.dart';
import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

class const ChatMessageBubble({
  super.key,
  required this.message,
  required this.isOutgoing,
  required this.animate,
  required this.onLoadImage,
  this.onRetry,
}) extends StatelessWidget {
  final ChatMessage message;
  final bool isOutgoing;
  final bool animate;
  final Future<Uint8List> Function(String messageId) onLoadImage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final formattedTime = _formatMessageTime(message.createdAt);
    final isFailed =
        isOutgoing &&
        message.deliveryStatus == ChatMessageDeliveryStatus.failed;
    final canRetry = isFailed && onRetry != null && !message.hasImage;

    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      padding: message.hasImage
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.75,
      ),
      decoration: message.hasImage
          ? null
          : BoxDecoration(
              color: isOutgoing
                  ? colors.primary
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppRadius.lg),
                topRight: const Radius.circular(AppRadius.lg),
                bottomLeft: Radius.circular(isOutgoing ? 20 : 4),
                bottomRight: Radius.circular(isOutgoing ? 4 : 20),
              ),
            ),
      child: message.hasImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: ChatPicture(load: () => onLoadImage(message.id)),
            )
          : Text(
              message.text,
              style: context.textStyles.bodyMedium?.copyWith(
                color: isOutgoing ? colors.onPrimary : colors.onSurface,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
    );

    return AppChatMessageTransition(
      key: ValueKey<String>('chat-message-${message.identityKey}'),
      animate: animate,
      isOutgoing: isOutgoing,
      child: Align(
        alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isOutgoing
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (canRetry)
              Semantics(
                button: true,
                label: 'Retry sending message',
                child: InkWell(
                  onTap: onRetry,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: bubble,
                ),
              )
            else
              bubble,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formattedTime,
                    style: context.textStyles.labelSmall?.tabular.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isOutgoing) ...[
                    const SizedBox(width: AppSpacing.xs),
                    AppChatDeliveryIndicator(
                      isSending:
                          message.deliveryStatus ==
                          ChatMessageDeliveryStatus.sending,
                      isDelivered:
                          message.deliveryStatus ==
                          ChatMessageDeliveryStatus.seen,
                      isFailed: isFailed,
                      color: isFailed
                          ? colors.error
                          : context.semanticColors.success,
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
}

String _formatMessageTime(DateTime dateTime) {
  final hourDisplay = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '$hourDisplay:$minute $period';
}

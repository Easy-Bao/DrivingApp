import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class const ChatComposer({
  super.key,
  required this.controller,
  required this.canSendMessage,
  required this.isConnected,
  required this.isRoomLocked,
  required this.isSendingImage,
  this.isSendingFromCamera = false,
  required this.lockReasonMessage,
  required this.onChanged,
  required this.onSend,
  required this.onCameraPressed,
  required this.onGalleryPressed,
}) extends StatelessWidget {
  final TextEditingController controller;
  final bool canSendMessage;
  final bool isConnected;
  final bool isRoomLocked;
  final bool isSendingImage;
  final bool isSendingFromCamera;
  final String lockReasonMessage;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final VoidCallback onCameraPressed;
  final VoidCallback onGalleryPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final hairline = colors.outlineVariant.withValues(alpha: 0.7);
    final quietIconStyle = AppQuietInteraction.iconButtonStyle(
      colors,
      foregroundColor: colors.onSurfaceVariant,
    );

    Widget uploadSpinner() => SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: colors.onSurface),
    );

    return SafeArea(
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Take photo',
              onPressed: canSendMessage && !isSendingImage
                  ? onCameraPressed
                  : null,
              style: quietIconStyle,
              icon: isSendingImage && isSendingFromCamera
                  ? uploadSpinner()
                  : const Icon(LucideIcons.camera, size: 19),
            ),
            IconButton(
              tooltip: 'Attach photo file',
              onPressed: canSendMessage && !isSendingImage
                  ? onGalleryPressed
                  : null,
              style: quietIconStyle,
              icon: isSendingImage && !isSendingFromCamera
                  ? uploadSpinner()
                  : const Icon(LucideIcons.paperclip, size: 19),
            ),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 46),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.canvasColor,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: TextField(
                      controller: controller,
                      readOnly: !canSendMessage,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: colors.onSurface,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        fillColor: Colors.transparent,
                        hintText: isRoomLocked
                            ? lockReasonMessage
                            : isConnected
                            ? 'Type a message...'
                            : 'Reconnect to send a message',
                        hintStyle: context.textStyles.bodyMedium?.copyWith(
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
                      onChanged: onChanged,
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: canSendMessage
                    ? colors.primary
                    : colors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                tooltip: 'Send message',
                icon: const Icon(LucideIcons.send_horizontal, size: 18),
                style: AppQuietInteraction.iconButtonStyle(
                  colors,
                  foregroundColor: canSendMessage
                      ? colors.onPrimary
                      : colors.onSurfaceVariant,
                  overlayBaseColor: colors.onPrimary,
                  focusAlpha: 0.16,
                ),
                constraints: const BoxConstraints(
                  minWidth: AppSize.minimumTouchTarget,
                  minHeight: AppSize.minimumTouchTarget,
                ),
                color: canSendMessage
                    ? colors.onPrimary
                    : colors.onSurfaceVariant,
                onPressed: canSendMessage ? onSend : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class const ChatEndedFooter({super.key, this.reasonMessage})
    extends StatelessWidget {
  final String? reasonMessage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final detail = reasonMessage?.trim();
    final hasDetail = detail != null && detail.isNotEmpty;
    return Semantics(
      container: true,
      liveRegion: true,
      child: SafeArea(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This conversation has ended',
                textAlign: TextAlign.center,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hasDetail) ...[
                const SizedBox(height: 2),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

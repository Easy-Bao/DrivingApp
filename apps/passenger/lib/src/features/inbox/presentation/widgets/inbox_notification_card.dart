import 'package:design_system/design_system.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger/src/features/inbox/presentation/formatters/inbox_presenter.dart';

class InboxNotificationCard extends StatelessWidget {
  const InboxNotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    this.presenter,
    this.isExpanded = false,
    this.onDelete,
    this.showBottomDivider = true,
  });

  final InboxNotification notification;
  final VoidCallback onTap;
  final InboxPresenter? presenter;
  final bool isExpanded;
  final VoidCallback? onDelete;
  final bool showBottomDivider;

  @override
  Widget build(BuildContext context) {
    final resolvedPresenter =
        presenter ??
        InboxPresenter(
          DateTime.now(),
          alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
        );
    final message = resolvedPresenter.normalizedMessage(notification);
    final category = resolvedPresenter.categoryOf(notification);
    final isOpenableChat = resolvedPresenter.isOpenableChat(notification);
    final isUnread = !notification.isRead;
    final timestampLabel = resolvedPresenter.formatTimestamp(
      notification.timestamp,
    );
    final isLargeText = MediaQuery.textScalerOf(context).scale(14) > 18;

    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final icon = switch (category) {
      InboxNotificationCategory.message => LucideIcons.message_circle,
      InboxNotificationCategory.receipt => LucideIcons.receipt,
      InboxNotificationCategory.ride => LucideIcons.navigation,
      InboxNotificationCategory.general => LucideIcons.bell,
    };

    final animationDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);

    final semanticPrefix = isUnread ? 'Unread. ' : '';
    final semanticHint = isOpenableChat
        ? 'Opens conversation'
        : isExpanded
        ? 'Collapses notification details'
        : 'Shows notification details';

    final titleWidget = Text(
      notification.title,
      maxLines: isExpanded ? null : 2,
      overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
      style: textStyles.titleSmall?.copyWith(
        fontSize: 15,
        height: 1.3,
        color: isUnread
            ? colorScheme.onSurface
            : colorScheme.onSurface.withValues(alpha: 0.88),
        fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
      ),
    );

    final timestampWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            timestampLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyles.labelSmall?.tabular.copyWith(
              color: isUnread
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
              fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
              letterSpacing: 0.1,
            ),
          ),
        ),
        if (isUnread) ...[
          const SizedBox(width: 6),
          ExcludeSemantics(
            child: Container(
              key: ValueKey<String>('inbox-unread-dot-${notification.id}'),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ],
    );

    return Semantics(
      button: true,
      label: '$semanticPrefix${notification.title}. $message. $timestampLabel',
      hint: semanticHint,
      customSemanticsActions: onDelete == null
          ? null
          : <CustomSemanticsAction, VoidCallback>{
              const CustomSemanticsAction(label: 'Delete notification'):
                  onDelete!,
            },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: isUnread
                ? colorScheme.surfaceContainerLowest
                : Colors.transparent,
            borderRadius: isUnread
                ? BorderRadius.circular(AppRadius.md)
                : BorderRadius.zero,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: ValueKey<String>('inbox-notification-${notification.id}'),
              onTap: onTap,
              enableFeedback: false,
              splashFactory: NoSplash.splashFactory,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.focused)) {
                  return colorScheme.primary.withValues(alpha: 0.12);
                }
                return Colors.transparent;
              }),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isUnread ? AppSpacing.md : AppSpacing.xs,
                  vertical: 15,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: ExcludeSemantics(
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isUnread
                                ? colorScheme.primaryContainer
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isUnread
                                  ? colorScheme.primary.withValues(alpha: 0.12)
                                  : colorScheme.outlineVariant,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            icon,
                            size: 17,
                            color: isUnread
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLargeText) ...[
                            titleWidget,
                            const SizedBox(height: 2),
                            timestampWidget,
                          ] else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: titleWidget),
                                const SizedBox(width: AppSpacing.md),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: timestampWidget,
                                ),
                              ],
                            ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  message,
                                  maxLines: isExpanded ? null : 2,
                                  overflow: isExpanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                  style: textStyles.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                              if (isOpenableChat) ...[
                                const SizedBox(width: AppSpacing.sm),
                                ExcludeSemantics(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Icon(
                                      LucideIcons.chevron_right,
                                      size: 16,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          AnimatedSize(
                            duration: animationDuration,
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topLeft,
                            child: isExpanded && !isOpenableChat
                                ? Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppSpacing.md,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Wrap(
                                        spacing: AppSpacing.md,
                                        runSpacing: AppSpacing.xs,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        alignment: WrapAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            resolvedPresenter
                                                .formatFullTimestamp(
                                                  notification.timestamp,
                                                ),
                                            style: textStyles
                                                .labelSmall
                                                ?.tabular
                                                .copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                  letterSpacing: 0.1,
                                                ),
                                          ),
                                          if (onDelete != null)
                                            TextButton.icon(
                                              key: ValueKey<String>(
                                                'inbox-delete-${notification.id}',
                                              ),
                                              onPressed: onDelete,
                                              style:
                                                  TextButton.styleFrom(
                                                    foregroundColor:
                                                        colorScheme.error,
                                                    enableFeedback: false,
                                                    splashFactory:
                                                        NoSplash.splashFactory,
                                                    minimumSize: const Size(
                                                      AppSize
                                                          .minimumTouchTarget,
                                                      AppSize
                                                          .minimumTouchTarget,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal:
                                                              AppSpacing.sm,
                                                        ),
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                  ).copyWith(
                                                    overlayColor:
                                                        WidgetStateProperty.resolveWith(
                                                          (states) {
                                                            if (states.contains(
                                                              WidgetState
                                                                  .focused,
                                                            )) {
                                                              return colorScheme
                                                                  .error
                                                                  .withValues(
                                                                    alpha: 0.12,
                                                                  );
                                                            }
                                                            return Colors
                                                                .transparent;
                                                          },
                                                        ),
                                                  ),
                                              icon: const Icon(
                                                LucideIcons.trash_2,
                                                size: 14,
                                              ),
                                              label: const Text('Delete'),
                                            ),
                                        ],
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showBottomDivider)
            Divider(
              height: 1,
              thickness: 1,
              indent: isUnread ? 64 : 56,
              color: colorScheme.outlineVariant.withValues(alpha: 0.65),
            ),
        ],
      ),
    );
  }
}

import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox_state.dart';
import 'package:skeletonizer/skeletonizer.dart';

ButtonStyle inboxQuietTextButtonStyle(
  BuildContext context, {
  EdgeInsetsGeometry? padding,
  AlignmentGeometry? alignment,
}) {
  final colorScheme = context.colorScheme;
  return TextButton.styleFrom(
    foregroundColor: colorScheme.onSurface,
    disabledForegroundColor: colorScheme.onSurfaceVariant.withValues(
      alpha: 0.42,
    ),
    padding: padding,
    alignment: alignment,
    enableFeedback: false,
    splashFactory: NoSplash.splashFactory,
  ).copyWith(
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused)) {
        return colorScheme.primary.withValues(alpha: 0.12);
      }
      return Colors.transparent;
    }),
  );
}

class InboxLoadingView extends StatelessWidget {
  const InboxLoadingView({
    super.key,
    required this.horizontalPadding,
    required this.bottomClearance,
  });

  final double horizontalPadding;
  final double bottomClearance;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.sm,
            horizontalPadding,
            AppSpacing.xl,
          ),
          sliver: const SliverToBoxAdapter(
            child: AppPageHeader(
              title: 'Inbox',
              subtitle: 'Messages and receipts',
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          sliver: Skeletonizer.sliver(
            key: const ValueKey<String>('inbox-loading-skeleton'),
            child: SliverList.builder(
              itemCount: 6,
              itemBuilder: (context, index) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (index == 0) ...[
                    const Bone.text(width: 56, fontSize: 12),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Bone.circle(size: 38),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Bone.text(width: 144, fontSize: 14),
                                  ),
                                  SizedBox(width: AppSpacing.md),
                                  Bone.text(width: 44, fontSize: 11),
                                ],
                              ),
                              SizedBox(height: 8),
                              Bone.multiText(lines: 2, fontSize: 13),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < 5)
                    Divider(
                      height: 1,
                      indent: 52,
                      color: context.colorScheme.outlineVariant.withValues(
                        alpha: 0.65,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: bottomClearance)),
      ],
    );
  }
}

class InboxHeader extends StatelessWidget {
  const InboxHeader({
    super.key,
    required this.isGuest,
    required this.loadedState,
    required this.notifications,
    required this.unreadCount,
    required this.contentWidth,
    required this.onMarkAllRead,
    required this.onRetryInbox,
    required this.onClearDismissError,
  });

  final bool isGuest;
  final InboxLoadedState? loadedState;
  final List<InboxNotification> notifications;
  final int unreadCount;
  final double contentWidth;
  final VoidCallback onMarkAllRead;
  final VoidCallback onRetryInbox;
  final VoidCallback onClearDismissError;

  @override
  Widget build(BuildContext context) {
    final inlineAction =
        contentWidth >= 320 &&
        MediaQuery.sizeOf(context).width >= 360 &&
        MediaQuery.textScalerOf(context).scale(14) <= 18;

    final action = !isGuest && loadedState != null && notifications.isNotEmpty
        ? TextButton(
            onPressed: loadedState!.isMarkingAllRead || unreadCount == 0
                ? null
                : onMarkAllRead,
            style: inboxQuietTextButtonStyle(
              context,
              padding: inlineAction
                  ? const EdgeInsets.only(left: AppSpacing.sm)
                  : const EdgeInsets.only(right: AppSpacing.sm),
              alignment: inlineAction
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
            ),
            child: Text(
              loadedState!.isMarkingAllRead ? 'Marking…' : 'Mark all as read',
            ),
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppPageHeader(
          title: 'Inbox',
          subtitle: 'Messages and receipts',
          trailing: inlineAction ? action : null,
        ),
        if (!inlineAction && action != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: action,
          ),
        if (loadedState?.markAllReadError case final markAllReadError?)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: AppErrorBanner(
              message: markAllReadError,
              onRetry: onMarkAllRead,
            ),
          ),
        if (loadedState?.dismissError case final dismissError?)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: AppErrorBanner(
              message: dismissError,
              onRetry: onRetryInbox,
              onDismiss: onClearDismissError,
            ),
          ),
      ],
    );
  }
}

class InboxDismissBackground extends StatelessWidget {
  const InboxDismissBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.xl),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.trash_2,
            color: colorScheme.onErrorContainer,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              'Delete',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.labelMedium?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InboxFooter extends StatelessWidget {
  const InboxFooter({super.key, required this.state, required this.onLoadMore});

  final InboxLoadedState state;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return Center(
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.colorScheme.onSurface,
          ),
        ),
      );
    }
    final isNetworkUnavailable = AppNetworkStatusScope.isUnavailableOf(context);
    final visibleLoadMoreError = isNetworkUnavailable
        ? null
        : state.loadMoreError;
    if (state.hasMore || visibleLoadMoreError != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (visibleLoadMoreError != null) ...[
            Text(
              visibleLoadMoreError,
              textAlign: TextAlign.center,
              style: context.textStyles.labelMedium?.copyWith(
                color: context.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs + 2),
          ],
          TextButton.icon(
            onPressed: onLoadMore,
            style: inboxQuietTextButtonStyle(context),
            icon: const Icon(LucideIcons.chevron_down, size: 16),
            label: Text(
              visibleLoadMoreError == null ? 'Load more messages' : 'Retry',
            ),
          ),
        ],
      );
    }
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(
              LucideIcons.check,
              size: 14,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          Flexible(
            child: Text(
              'You are all caught up',
              textAlign: TextAlign.center,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

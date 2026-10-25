import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/chat/chat_routes.dart';
import 'package:passenger/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox_cubit.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox_state.dart';
import 'package:passenger/src/features/inbox/presentation/widgets/inbox_empty_state.dart';
import 'package:passenger/src/features/inbox/presentation/widgets/inbox_notification_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({
    super.key,
    required this.inboxCubit,
    required this.sessionService,
  });

  final InboxCubit inboxCubit;
  final SessionStore sessionService;

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  late final InboxCubit _inboxCubit;

  @override
  void initState() {
    super.initState();
    _inboxCubit = widget.inboxCubit;
    unawaited(_initializeInbox());
  }

  Future<void> _initializeInbox() async {
    final session = BlocProvider.of<SessionBloc>(context).state;
    if (session is! AuthenticatedSession) return;
    await _inboxCubit.loadNotifications(session.passengerId);
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppLayout.pagePadding,
            0,
            AppLayout.pagePadding,
            16,
          ),
          sliver: SliverToBoxAdapter(
            child: AppPageHeader(
              title: 'Inbox',
              subtitle: 'Messages and receipts',
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.pagePadding,
          ),
          sliver: _buildSkeletonNotifications(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InboxCubit>.value(
      value: _inboxCubit,
      child: Scaffold(
        body: SafeArea(
          child: BlocListener<SessionBloc, SessionState>(
            listenWhen: (_, current) => current is AuthenticatedSession,
            listener: (_, _) => unawaited(_initializeInbox()),
            child: BlocBuilder<SessionBloc, SessionState>(
              builder: (context, sessionState) => switch (sessionState) {
                SessionLoading() => _buildSessionLoadingState(),
                GuestSession() || SessionFailure() => _buildInboxContent(
                  const InboxLoadedState(<InboxNotification>[]),
                  isGuest: true,
                ),
                AuthenticatedSession() => BlocBuilder<InboxCubit, InboxState>(
                  builder: (context, state) {
                    if (state is InboxLoadingState) {
                      return _buildLoadingState();
                    }
                    if (state is InboxInitialState) {
                      return _buildInboxContent(
                        const InboxLoadedState(<InboxNotification>[]),
                        isGuest: false,
                      );
                    }
                    return _buildInboxContent(state, isGuest: false);
                  },
                ),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionLoadingState() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppLayout.pagePadding,
            0,
            AppLayout.pagePadding,
            16,
          ),
          sliver: SliverToBoxAdapter(
            child: AppPageHeader(
              title: 'Inbox',
              subtitle: 'Messages and receipts',
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.pagePadding,
          ),
          sliver: _buildSkeletonNotifications(),
        ),
      ],
    );
  }

  Widget _buildSkeletonNotifications() {
    return Skeletonizer.sliver(
      key: const ValueKey<String>('inbox-loading-skeleton'),
      child: SliverList.builder(
        itemCount: 6,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: context.colorScheme.outlineVariant),
            ),
            child: const Row(
              children: [
                Bone.circle(size: 42),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Bone.text(width: 150, fontSize: 14),
                      SizedBox(height: 6),
                      Bone.multiText(lines: 2, fontSize: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInboxContent(InboxState state, {required bool isGuest}) {
    final notifications = state is InboxLoadedState
        ? state.notifications
        : <InboxNotification>[];
    final loadedState = state is InboxLoadedState ? state : null;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppLayout.pagePadding,
            0,
            AppLayout.pagePadding,
            16,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const AppPageHeader(
                title: 'Inbox',
                subtitle: 'Messages and receipts',
              ),
              if (!isGuest && loadedState != null && notifications.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed:
                        loadedState.isMarkingAllRead ||
                            !notifications.any((item) => !item.isRead)
                        ? null
                        : () => unawaited(
                            _inboxCubit.markAllNotificationsAsRead(),
                          ),
                    child: Text(
                      loadedState.isMarkingAllRead
                          ? 'Marking…'
                          : 'Mark all as read',
                    ),
                  ),
                ),
              if (loadedState?.markAllReadError != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    loadedState!.markAllReadError!,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm * 2),
            ]),
          ),
        ),
        if (state is InboxErrorState)
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppLayout.pagePadding,
            ),
            sliver: SliverToBoxAdapter(
              child: AppErrorBanner(
                message: state.message,
                onRetry: () => unawaited(_initializeInbox()),
              ),
            ),
          )
        else if (notifications.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: InboxEmptyState(isGuest: isGuest),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppLayout.pagePadding,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final notification = notifications[index];
                return Padding(
                  key: ValueKey(notification.id),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: ColoredBox(
                      color: context.colorScheme.error.withValues(alpha: 0.1),
                      child: Dismissible(
                        key: Key(notification.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) =>
                            _inboxCubit.dismissNotification(index),
                        background: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 24),
                            child: Icon(
                              LucideIcons.trash_2,
                              color: context.colorScheme.error,
                              size: 20,
                            ),
                          ),
                        ),
                        child: InboxNotificationCard(
                          notification: notification,
                          onTap: () =>
                              unawaited(_openNotification(notification, index)),
                        ),
                      ),
                    ),
                  ),
                );
              }, childCount: notifications.length),
            ),
          ),
        if (notifications.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 36.0),
            sliver: SliverToBoxAdapter(child: _buildFooter(loadedState!)),
          ),
      ],
    );
  }

  Widget _buildFooter(InboxLoadedState state) {
    if (state.isLoadingMore) {
      return Center(
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.colorScheme.onSurface,
          ),
        ),
      );
    }
    final isNetworkUnavailable = AppNetworkStatusScope.isUnavailableOf(context);
    final showLoadMoreError =
        state.loadMoreError != null && !isNetworkUnavailable;
    if (state.hasMore || showLoadMoreError) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLoadMoreError) ...[
            Text(
              state.loadMoreError!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colorScheme.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
          ],
          TextButton.icon(
            onPressed: _inboxCubit.loadMoreNotifications,
            icon: const Icon(LucideIcons.chevron_down, size: 16),
            label: Text(
              state.loadMoreError == null || isNetworkUnavailable
                  ? 'Load more messages'
                  : 'Retry',
            ),
          ),
        ],
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.mail,
            size: 24,
            color: context.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'You are all caught up',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openNotification(
    InboxNotification notification,
    int index,
  ) async {
    _inboxCubit.markNotificationAsRead(index);
    if (notification.type != 'chat' ||
        notification.roomId == null ||
        notification.userId == null ||
        notification.peerId == null) {
      return;
    }
    if (!mounted) return;
    await context.pushNamed(
      ChatRoutes.driverChat,
      extra: {
        'roomId': notification.roomId,
        'userId': notification.userId,
        'peerId': notification.peerId,
        'peerName': notification.peerName ?? 'Driver',
      },
    );
  }
}

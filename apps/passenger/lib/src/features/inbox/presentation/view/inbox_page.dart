import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/chat/chat_routes.dart';
import 'package:passenger/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox/inbox_cubit.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox/inbox_state.dart';
import 'package:passenger/src/features/inbox/presentation/widgets/inbox_empty_state_widget.dart';
import 'package:passenger/src/features/inbox/presentation/widgets/inbox_notification_card_widget.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';

class const InboxPage({
  super.key,
  required this.inboxCubit,
  required this.sessionService,
}) extends StatefulWidget {
  final InboxCubit inboxCubit;
  final PassengerSessionStore sessionService;

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
    if (BlocProvider.of<SessionBloc>(context).state is! AuthenticatedSession) {
      return;
    }
    if (_inboxCubit.state is! InboxLoadedState) {
      final passengerId = await widget.sessionService.readPassengerId() ?? '';
      if (passengerId.isNotEmpty) {
        unawaited(_inboxCubit.loadNotifications(passengerId));
      }
    }
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(
            EasyRideDesignTokens.pageHorizontalPadding,
            0,
            EasyRideDesignTokens.pageHorizontalPadding,
            16,
          ),
          sliver: SliverToBoxAdapter(
            child: EasyRidePageHeader(
              title: 'Inbox',
              subtitle: 'Messages and receipts',
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: context.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Loading your inbox',
                  style: context.textStyles.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Messages and receipts will appear here.',
                  style: context.textStyles.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InboxCubit>.value(
      value: _inboxCubit,
      child: Scaffold(
        backgroundColor: context.canvasColor,
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
    return const CustomScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            EasyRideDesignTokens.pageHorizontalPadding,
            0,
            EasyRideDesignTokens.pageHorizontalPadding,
            16,
          ),
          sliver: SliverToBoxAdapter(
            child: EasyRidePageHeader(
              title: 'Inbox',
              subtitle: 'Messages and receipts',
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      ],
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
            EasyRideDesignTokens.pageHorizontalPadding,
            0,
            EasyRideDesignTokens.pageHorizontalPadding,
            16,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const EasyRidePageHeader(
                title: 'Inbox',
                subtitle: 'Messages and receipts',
              ),
              const SizedBox(height: EasyRideDesignTokens.compactGap * 2),
            ]),
          ),
        ),
        if (notifications.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: InboxEmptyStateWidget(isGuest: isGuest),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: EasyRideDesignTokens.pageHorizontalPadding,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final notification = notifications[index];
                return Dismissible(
                  key: Key(notification.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _inboxCubit.dismissNotification(index),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: context.colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      LucideIcons.trash_2,
                      color: context.colorScheme.error,
                      size: 20,
                    ),
                  ),
                  child: InboxNotificationCardWidget(
                    notification: notification,
                    onTap: () =>
                        unawaited(_openNotification(notification, index)),
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
    if (state.hasMore || state.loadMoreError != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.loadMoreError != null) ...[
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
              state.loadMoreError == null ? 'Load more messages' : 'Retry',
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

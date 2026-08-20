import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/chat/chat_routes.dart';
import 'package:passenger_app/src/features/inbox/bloc/inbox/inbox_cubit.dart';
import 'package:passenger_app/src/features/inbox/bloc/inbox/inbox_state.dart';
import 'package:passenger_app/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger_app/src/features/inbox/view/widgets/inbox_empty_state_widget.dart';
import 'package:passenger_app/src/features/inbox/view/widgets/inbox_notification_card_widget.dart';
import 'package:skeletonizer/skeletonizer.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  late final InboxCubit _inboxCubit;

  @override
  void initState() {
    super.initState();
    _inboxCubit = Modular.get<InboxCubit>();
    unawaited(_initializeInbox());
  }

  Future<void> _initializeInbox() async {
    if (_inboxCubit.state is! InboxLoadedState) {
      final passengerId =
          await Modular.get<SecureSessionService>().readPassengerId() ?? '';
      if (passengerId.isNotEmpty) {
        unawaited(_inboxCubit.loadNotifications(passengerId));
      }
    }
  }

  Widget _buildLoadingState() {
    return Skeletonizer.zone(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bone.text(width: 100, fontSize: 32),
                  SizedBox(height: 4),
                  Bone.text(width: 160, fontSize: 15),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildLoadingNotification(),
                childCount: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingNotification() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.neutralColor.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderSide.withValues(alpha: 0.2)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Bone.circle(size: 48),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bone.text(width: 130, fontSize: 15),
                  SizedBox(height: 4),
                  Bone.text(width: 180, fontSize: 13),
                ],
              ),
            ),
            SizedBox(width: 12),
            Bone.text(width: 48, fontSize: 11),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InboxCubit>.value(
      value: _inboxCubit,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: SafeArea(
          child: BlocBuilder<InboxCubit, InboxState>(
            builder: (context, state) {
              if (state is InboxLoadingState || state is InboxInitialState) {
                return _buildLoadingState();
              }

              final notifications = state is InboxLoadedState
                  ? state.notifications
                  : <InboxNotification>[];

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 16.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const Text(
                          'Inbox',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Messages and receipts',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ]),
                    ),
                  ),
                  if (notifications.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: InboxEmptyStateWidget(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final notification = notifications[index];
                          return Dismissible(
                            key: Key(notification.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) =>
                                _inboxCubit.dismissNotification(index),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.cancel.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                LucideIcons.trash_2,
                                color: AppTheme.cancel,
                                size: 20,
                              ),
                            ),
                            child: InboxNotificationCardWidget(
                              notification: notification,
                              onTap: () => unawaited(
                                _openNotification(notification, index),
                              ),
                            ),
                          );
                        }, childCount: notifications.length),
                      ),
                    ),
                  if (notifications.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(vertical: 36.0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.mail,
                                  size: 24,
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You are all caught up',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openNotification(
    InboxNotification notification,
    int index,
  ) async {
    _inboxCubit.markNotificationAsRead(index);
    if (notification.type != 'chat' ||
        notification.isExpired ||
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

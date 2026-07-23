import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/inbox/data/repositories/inbox_repository_impl.dart';
import 'package:passenger_app/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger_app/src/features/inbox/presentation/bloc/inbox_cubit.dart';
import 'package:passenger_app/src/features/inbox/presentation/bloc/inbox_state.dart';
import 'package:passenger_app/src/features/inbox/presentation/widgets/inbox_empty_state_widget.dart';
import 'package:passenger_app/src/features/inbox/presentation/widgets/inbox_notification_card_widget.dart';
import 'package:passenger_services/passenger_services.dart';
import 'package:session_service/session_service.dart';
import 'package:shared_ui/shared_ui.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late final InboxCubit _inboxCubit;

  @override
  void initState() {
    super.initState();
    final repo = InboxRepositoryImpl(
      remoteDataSource: Modular.get<PassengerRemoteDataSource>(),
    );
    _inboxCubit = InboxCubit(inboxRepository: repo);
    unawaited(_initializeInbox());
  }

  @override
  void dispose() {
    unawaited(_inboxCubit.close());
    super.dispose();
  }

  Future<void> _initializeInbox() async {
    final passengerId =
        await Modular.get<SecureSessionService>().readPassengerId() ?? '';
    if (passengerId.isNotEmpty) {
      unawaited(_inboxCubit.loadNotifications(passengerId));
    }
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
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                );
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
                              onTap: () =>
                                  _inboxCubit.markNotificationAsRead(index),
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
}

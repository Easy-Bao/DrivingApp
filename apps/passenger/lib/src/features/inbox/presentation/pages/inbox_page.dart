import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/chat/chat_routes.dart';
import 'package:passenger/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox_cubit.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox_state.dart';
import 'package:passenger/src/features/inbox/presentation/formatters/inbox_presenter.dart';
import 'package:passenger/src/features/inbox/presentation/widgets/inbox_empty_state.dart';
import 'package:passenger/src/features/inbox/presentation/widgets/inbox_filter_bar.dart';
import 'package:passenger/src/features/inbox/presentation/widgets/inbox_notification_card.dart';
import 'package:passenger/src/features/inbox/presentation/widgets/inbox_page_sections.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key, required this.inboxCubit});

  final InboxCubit inboxCubit;

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage>
    with SingleTickerProviderStateMixin {
  static const Duration _filterTransitionDuration = Duration(milliseconds: 240);

  late final InboxCubit _inboxCubit;
  late final AnimationController _filterTransitionController;
  late final CurvedAnimation _filterTransitionCurve;
  InboxFilter _selectedFilter = InboxFilter.all;
  double _filterSlideDirection = 0;
  String? _expandedNotificationId;
  final Set<String> _keptVisibleInUnreadFilter = <String>{};
  int _keptVisibleRevision = 0;

  List<InboxNotification>? _cachedNotifications;
  InboxFilter? _cachedFilter;
  int _cachedKeptVisibleRevision = -1;
  bool? _cachedAlwaysUse24HourFormat;
  late InboxPresenter _cachedPresenter;
  int _cachedUnreadCount = 0;
  List<InboxNotification> _cachedVisibleNotifications = const [];
  Map<String, List<InboxNotification>> _cachedGroupedNotifications = const {};

  @override
  void initState() {
    super.initState();
    _inboxCubit = widget.inboxCubit;
    _filterTransitionController = AnimationController(
      vsync: this,
      duration: _filterTransitionDuration,
      value: 1,
    );
    _filterTransitionCurve = CurvedAnimation(
      parent: _filterTransitionController,
      curve: Curves.easeOutCubic,
    );
    unawaited(_initializeInbox());
  }

  @override
  void dispose() {
    _filterTransitionCurve.dispose();
    _filterTransitionController.dispose();
    super.dispose();
  }

  Future<void> _initializeInbox() async {
    if (_keptVisibleInUnreadFilter.isNotEmpty && mounted) {
      setState(() {
        _keptVisibleInUnreadFilter.clear();
        _keptVisibleRevision++;
      });
    }
    final session = BlocProvider.of<SessionBloc>(context).state;
    if (session is! AuthenticatedSession) return;
    await _inboxCubit.loadNotifications(session.passengerId);
  }

  void _syncMemoizedNotifications(
    List<InboxNotification> notifications, {
    required bool alwaysUse24HourFormat,
  }) {
    final notificationsUnchanged =
        identical(_cachedNotifications, notifications) ||
        listEquals(_cachedNotifications, notifications);
    if (notificationsUnchanged &&
        _cachedFilter == _selectedFilter &&
        _cachedKeptVisibleRevision == _keptVisibleRevision &&
        _cachedAlwaysUse24HourFormat == alwaysUse24HourFormat) {
      return;
    }

    _cachedNotifications = notifications;
    _cachedFilter = _selectedFilter;
    _cachedKeptVisibleRevision = _keptVisibleRevision;
    _cachedAlwaysUse24HourFormat = alwaysUse24HourFormat;

    _cachedPresenter = InboxPresenter(
      DateTime.now(),
      alwaysUse24HourFormat: alwaysUse24HourFormat,
    );
    _cachedUnreadCount = _cachedPresenter.unreadCount(notifications);
    _cachedVisibleNotifications = _selectedFilter == InboxFilter.unread
        ? notifications
              .where(
                (item) =>
                    !item.isRead ||
                    _keptVisibleInUnreadFilter.contains(item.id),
              )
              .toList(growable: false)
        : _cachedPresenter.filter(notifications, _selectedFilter);
    _cachedGroupedNotifications = _cachedPresenter.groupByDate(
      _cachedVisibleNotifications,
    );
  }

  double _horizontalPaddingFor(double viewportWidth) {
    final basePadding = viewportWidth >= AppLayout.wideBreakpoint
        ? AppLayout.pagePaddingWide
        : AppLayout.pagePadding;
    final maxConstrainedWidth = AppLayout.pageMaxWidth + (basePadding * 2);
    if (viewportWidth > maxConstrainedWidth) {
      return (viewportWidth - AppLayout.pageMaxWidth) / 2;
    }
    return basePadding;
  }

  double _bottomClearance(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= AppLayout.wideBreakpoint;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    if (isWide) return safeBottom + AppSpacing.xxxl;
    return AppFloatingTabBar.height + safeBottom + AppSpacing.xxl;
  }

  Widget _wrapFilterTransition(Widget child) {
    return AnimatedBuilder(
      animation: _filterTransitionCurve,
      builder: (context, animatedChild) {
        final progress = _filterTransitionCurve.value;
        final dx = _filterSlideDirection * 14 * (1 - progress);
        return Opacity(
          opacity: progress.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: animatedChild,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InboxCubit>.value(
      value: _inboxCubit,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = _horizontalPaddingFor(
                constraints.maxWidth,
              );
              final contentWidth =
                  (constraints.maxWidth - (horizontalPadding * 2)).clamp(
                    0.0,
                    AppLayout.pageMaxWidth,
                  );

              return BlocListener<SessionBloc, SessionState>(
                listenWhen: (_, current) => current is AuthenticatedSession,
                listener: (_, _) => unawaited(_initializeInbox()),
                child: BlocBuilder<SessionBloc, SessionState>(
                  builder: (context, sessionState) => switch (sessionState) {
                    SessionLoading() => InboxLoadingView(
                      horizontalPadding: horizontalPadding,
                      bottomClearance: _bottomClearance(context),
                    ),
                    GuestSession() || SessionFailure() => _buildInboxContent(
                      const InboxLoadedState(<InboxNotification>[]),
                      isGuest: true,
                      horizontalPadding: horizontalPadding,
                      contentWidth: contentWidth,
                    ),
                    AuthenticatedSession() => RefreshIndicator(
                      color: context.colorScheme.onSurface,
                      backgroundColor:
                          context.colorScheme.surfaceContainerLowest,
                      onRefresh: _initializeInbox,
                      child: BlocBuilder<InboxCubit, InboxState>(
                        builder: (context, state) {
                          if (state is InboxLoadingState ||
                              state is InboxInitialState) {
                            return InboxLoadingView(
                              horizontalPadding: horizontalPadding,
                              bottomClearance: _bottomClearance(context),
                            );
                          }
                          return _buildInboxContent(
                            state,
                            isGuest: false,
                            horizontalPadding: horizontalPadding,
                            contentWidth: contentWidth,
                          );
                        },
                      ),
                    ),
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInboxContent(
    InboxState state, {
    required bool isGuest,
    required double horizontalPadding,
    required double contentWidth,
  }) {
    final notifications = state is InboxLoadedState
        ? state.notifications
        : const <InboxNotification>[];
    final loadedState = state is InboxLoadedState ? state : null;
    _syncMemoizedNotifications(
      notifications,
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final presenter = _cachedPresenter;
    final unreadCount = _cachedUnreadCount;
    final visibleNotifications = _cachedVisibleNotifications;
    final groupedNotifications = _cachedGroupedNotifications;
    final bottomClearance = _bottomClearance(context);
    final showFilters =
        !isGuest && loadedState != null && notifications.isNotEmpty;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.sm,
            horizontalPadding,
            showFilters ? AppSpacing.md : AppSpacing.lg,
          ),
          sliver: SliverToBoxAdapter(
            child: InboxHeader(
              isGuest: isGuest,
              loadedState: loadedState,
              notifications: notifications,
              unreadCount: unreadCount,
              contentWidth: contentWidth,
              onMarkAllRead: () {
                if (_keptVisibleInUnreadFilter.isNotEmpty) {
                  setState(() {
                    _keptVisibleInUnreadFilter.clear();
                    _keptVisibleRevision++;
                  });
                }
                unawaited(_inboxCubit.markAllNotificationsAsRead());
              },
              onRetryInbox: () => unawaited(_initializeInbox()),
              onClearDismissError: _inboxCubit.clearDismissError,
            ),
          ),
        ),
        if (showFilters)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              AppSpacing.lg,
            ),
            sliver: SliverToBoxAdapter(
              child: InboxFilterBar(
                selectedFilter: _selectedFilter,
                unreadCount: unreadCount,
                onSelected: _selectFilter,
              ),
            ),
          ),
        if (state is InboxErrorState)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
            child: InboxEmptyState(
              isGuest: isGuest,
              bottomPadding: bottomClearance,
            ),
          )
        else if (visibleNotifications.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _wrapFilterTransition(
              InboxEmptyState(
                filter: _selectedFilter,
                onResetFilter: () => _selectFilter(InboxFilter.all),
                bottomPadding: bottomClearance,
              ),
            ),
          )
        else
          ..._buildGroupedSlivers(
            groupedNotifications: groupedNotifications,
            presenter: presenter,
            horizontalPadding: horizontalPadding,
          ),
        if (visibleNotifications.isNotEmpty && loadedState != null)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              AppSpacing.xxl,
              horizontalPadding,
              bottomClearance,
            ),
            sliver: SliverToBoxAdapter(
              child: _wrapFilterTransition(
                InboxFooter(
                  state: loadedState,
                  onLoadMore: _inboxCubit.loadMoreNotifications,
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildGroupedSlivers({
    required Map<String, List<InboxNotification>> groupedNotifications,
    required InboxPresenter presenter,
    required double horizontalPadding,
  }) {
    final slivers = <Widget>[];
    final entries = groupedNotifications.entries.toList();

    for (var groupIndex = 0; groupIndex < entries.length; groupIndex++) {
      final entry = entries[groupIndex];
      final items = entry.value;

      slivers
        ..add(
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              groupIndex == 0 ? AppSpacing.xs : AppSpacing.xl,
              horizontalPadding,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: _wrapFilterTransition(
                Semantics(
                  header: true,
                  child: Text(
                    entry.key.toUpperCase(),
                    style: context.textStyles.labelSmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.9,
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
        ..add(
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            sliver: SliverList.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final notification = items[index];
                final isLastInGroup = index == items.length - 1;
                final isExpanded = _expandedNotificationId == notification.id;

                return _wrapFilterTransition(
                  Dismissible(
                    key: ValueKey<String>(
                      'inbox-dismissible-${notification.id}',
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _dismissNotification(notification.id),
                    background: const InboxDismissBackground(),
                    child: InboxNotificationCard(
                      notification: notification,
                      presenter: presenter,
                      isExpanded: isExpanded,
                      showBottomDivider: !isLastInGroup,
                      onDelete: () => _dismissNotification(notification.id),
                      onTap: () =>
                          unawaited(_openNotification(notification, presenter)),
                    ),
                  ),
                );
              },
            ),
          ),
        );
    }

    return slivers;
  }

  void _selectFilter(InboxFilter filter) {
    if (filter == _selectedFilter) return;
    final direction = filter.index > _selectedFilter.index ? 1.0 : -1.0;
    setState(() {
      _filterSlideDirection = direction;
      _selectedFilter = filter;
      _expandedNotificationId = null;
      _keptVisibleInUnreadFilter.clear();
      _keptVisibleRevision++;
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _filterTransitionController.value = 1;
    } else {
      unawaited(_filterTransitionController.forward(from: 0));
    }
  }

  void _dismissNotification(String notificationId) {
    if (mounted &&
        (_expandedNotificationId == notificationId ||
            _keptVisibleInUnreadFilter.contains(notificationId))) {
      setState(() {
        if (_expandedNotificationId == notificationId) {
          _expandedNotificationId = null;
        }
        if (_keptVisibleInUnreadFilter.remove(notificationId)) {
          _keptVisibleRevision++;
        }
      });
    }
    _inboxCubit.dismissNotificationById(notificationId);
  }

  Future<void> _openNotification(
    InboxNotification notification,
    InboxPresenter presenter,
  ) async {
    _inboxCubit.markNotificationAsReadById(notification.id);
    if (!presenter.isOpenableChat(notification)) {
      if (!mounted) return;
      setState(() {
        final isCollapsing = _expandedNotificationId == notification.id;
        _expandedNotificationId = isCollapsing ? null : notification.id;
        if (_selectedFilter == InboxFilter.unread) {
          if (isCollapsing) {
            if (_keptVisibleInUnreadFilter.remove(notification.id)) {
              _keptVisibleRevision++;
            }
          } else if (_keptVisibleInUnreadFilter.add(notification.id)) {
            _keptVisibleRevision++;
          }
        }
      });
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

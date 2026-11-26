import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
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
import 'package:skeletonizer/skeletonizer.dart';

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
  late final Animation<double> _filterTransitionCurve;
  InboxFilter _selectedFilter = InboxFilter.all;
  double _filterSlideDirection = 0;
  String? _expandedNotificationId;
  final Set<String> _keptVisibleInUnreadFilter = <String>{};

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
    _filterTransitionController.dispose();
    super.dispose();
  }

  Future<void> _initializeInbox() async {
    if (_keptVisibleInUnreadFilter.isNotEmpty && mounted) {
      setState(_keptVisibleInUnreadFilter.clear);
    }
    final session = BlocProvider.of<SessionBloc>(context).state;
    if (session is! AuthenticatedSession) return;
    await _inboxCubit.loadNotifications(session.passengerId);
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

  ButtonStyle _quietTextButtonStyle(
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
                    SessionLoading() => _buildLoadingView(
                      horizontalPadding: horizontalPadding,
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
                          if (state is InboxLoadingState) {
                            return _buildLoadingView(
                              horizontalPadding: horizontalPadding,
                            );
                          }
                          if (state is InboxInitialState) {
                            return _buildInboxContent(
                              const InboxLoadedState(<InboxNotification>[]),
                              isGuest: false,
                              horizontalPadding: horizontalPadding,
                              contentWidth: contentWidth,
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

  Widget _buildLoadingView({required double horizontalPadding}) {
    final bottomClearance = _bottomClearance(context);
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
          sliver: _buildSkeletonNotifications(),
        ),
        SliverToBoxAdapter(child: SizedBox(height: bottomClearance)),
      ],
    );
  }

  Widget _buildSkeletonNotifications() {
    return Skeletonizer.sliver(
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    final presenter = InboxPresenter(
      DateTime.now(),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final unreadCount = presenter.unreadCount(notifications);
    final visibleNotifications = _selectedFilter == InboxFilter.unread
        ? notifications
              .where(
                (item) =>
                    !item.isRead ||
                    _keptVisibleInUnreadFilter.contains(item.id),
              )
              .toList()
        : presenter.filter(notifications, _selectedFilter);
    final groupedNotifications = presenter.groupByDate(visibleNotifications);
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
            child: _buildHeader(
              isGuest: isGuest,
              loadedState: loadedState,
              notifications: notifications,
              unreadCount: unreadCount,
              contentWidth: contentWidth,
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
              child: _wrapFilterTransition(_buildFooter(loadedState)),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader({
    required bool isGuest,
    required InboxLoadedState? loadedState,
    required List<InboxNotification> notifications,
    required int unreadCount,
    required double contentWidth,
  }) {
    final inlineAction =
        contentWidth >= 320 &&
        MediaQuery.sizeOf(context).width >= 360 &&
        MediaQuery.textScalerOf(context).scale(14) <= 18;

    final action = !isGuest && loadedState != null && notifications.isNotEmpty
        ? TextButton(
            onPressed: loadedState.isMarkingAllRead || unreadCount == 0
                ? null
                : () {
                    if (_keptVisibleInUnreadFilter.isNotEmpty) {
                      setState(_keptVisibleInUnreadFilter.clear);
                    }
                    unawaited(_inboxCubit.markAllNotificationsAsRead());
                  },
            style: _quietTextButtonStyle(
              context,
              padding: inlineAction
                  ? const EdgeInsets.only(left: AppSpacing.sm)
                  : const EdgeInsets.only(right: AppSpacing.sm),
              alignment: inlineAction
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
            ),
            child: Text(
              loadedState.isMarkingAllRead ? 'Marking…' : 'Mark all as read',
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
              onRetry: () =>
                  unawaited(_inboxCubit.markAllNotificationsAsRead()),
            ),
          ),
        if (loadedState?.dismissError case final dismissError?)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: AppErrorBanner(
              message: dismissError,
              onRetry: () => unawaited(_initializeInbox()),
              onDismiss: _inboxCubit.clearDismissError,
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
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: context.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.trash_2,
                            color: context.colorScheme.onErrorContainer,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              'Delete',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.labelMedium?.copyWith(
                                color: context.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildFooter(InboxLoadedState state) {
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
            onPressed: _inboxCubit.loadMoreNotifications,
            style: _quietTextButtonStyle(context),
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

  void _selectFilter(InboxFilter filter) {
    if (filter == _selectedFilter) return;
    final direction = filter.index > _selectedFilter.index ? 1.0 : -1.0;
    setState(() {
      _filterSlideDirection = direction;
      _selectedFilter = filter;
      _expandedNotificationId = null;
      _keptVisibleInUnreadFilter.clear();
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
        _keptVisibleInUnreadFilter.remove(notificationId);
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
            _keptVisibleInUnreadFilter.remove(notification.id);
          } else {
            _keptVisibleInUnreadFilter.add(notification.id);
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

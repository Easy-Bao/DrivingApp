import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/active_ride/active_ride_routes.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/booking/booking_routes.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_history/ride_history_bloc.dart';
import 'package:passenger/src/features/ride_history/presentation/widgets/ride_history_header.dart';
import 'package:passenger/src/features/ride_history/presentation/widgets/ride_history_list_view.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';
import 'package:passenger/src/features/ride_history/ride_history_routes.dart';
import 'package:skeletonizer/skeletonizer.dart';

class RideHistoryPage extends StatefulWidget {
  const RideHistoryPage({
    this.title = 'Activity',
    this.subtitle = 'Tap a ride to see details',
    this.showBackButton = false,
    this.showHeaderSubtitle = true,
    this.showSummary = true,
    this.showFilters = true,
    super.key,
  });
  final String title;
  final String subtitle;
  final bool showBackButton;
  final bool showHeaderSubtitle;
  final bool showSummary;
  final bool showFilters;

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  static const int _defaultSkeletonCount = 3;
  static const int _maximumSkeletonCount = 4;

  bool _hasLoadedRideHistory = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasLoadedRideHistory) return;
    _hasLoadedRideHistory = true;
    unawaited(_loadRideHistory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasColor,
      body: BlocBuilder<RideHistoryBloc, RideHistoryState>(
        builder: (context, rideHistoryState) {
          return SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: context.colorScheme.onSurface,
              onRefresh: _loadRideHistory,
              child: BlocListener<SessionBloc, SessionState>(
                listenWhen: (_, current) => current is AuthenticatedSession,
                listener: (_, _) => unawaited(_loadRideHistory()),
                child: BlocBuilder<SessionBloc, SessionState>(
                  builder: (context, sessionState) => switch (sessionState) {
                    SessionLoading() => _RideHistoryLoadingView(
                      title: widget.title,
                      subtitle: 'Checking your account',
                      showBackButton: widget.showBackButton,
                      showSubtitle: widget.showHeaderSubtitle,
                      showSummary: widget.showSummary,
                      showFilters: widget.showFilters,
                      itemCount: _defaultSkeletonCount,
                    ),
                    GuestSession() ||
                    SessionFailure() => _RideHistoryMessageView(
                      headerTitle: widget.title,
                      subtitle: 'Your trips and receipts',
                      title: 'Your trips, in one place',
                      message: 'Sign in or create an account to view your trips and receipts.',
                      showBackButton: widget.showBackButton,
                      showSubtitle: widget.showHeaderSubtitle,
                    ),
                    AuthenticatedSession() =>
                      BlocBuilder<RideHistoryBloc, RideHistoryState>(
                        builder: (context, state) => switch (state) {
                          RideHistoryInitial() => _RideHistoryLoadingView(
                            title: widget.title,
                            subtitle: 'Preparing your activity',
                            showBackButton: widget.showBackButton,
                            showSubtitle: widget.showHeaderSubtitle,
                            showSummary: widget.showSummary,
                            showFilters: widget.showFilters,
                            itemCount: _defaultSkeletonCount,
                          ),
                          RideHistoryLoading(:final existingRideCount)
                              when existingRideCount > 0 =>
                            _RideHistoryLoadingView(
                              title: widget.title,
                              subtitle: widget.subtitle,
                              showBackButton: widget.showBackButton,
                              showSubtitle: widget.showHeaderSubtitle,
                              showSummary: widget.showSummary,
                              showFilters: widget.showFilters,
                              itemCount: existingRideCount
                                  .clamp(
                                    _defaultSkeletonCount,
                                    _maximumSkeletonCount,
                                  )
                                  .toInt(),
                            ),
                          RideHistoryLoading() => _RideHistoryLoadingView(
                            title: widget.title,
                            subtitle: 'Loading your activity',
                            showBackButton: widget.showBackButton,
                            showSubtitle: widget.showHeaderSubtitle,
                            showSummary: widget.showSummary,
                            showFilters: widget.showFilters,
                            itemCount: _defaultSkeletonCount,
                          ),
                          RideHistoryError(
                            :final message,
                            :final failureKind,
                            :final retryAutomatically,
                          ) =>
                            _RideHistoryMessageView(
                              headerTitle: widget.title,
                              subtitle: widget.subtitle,
                              title: switch (failureKind) {
                                RideHistoryFailureKind.connection =>
                                  'Connection problem',
                                RideHistoryFailureKind.server => 'Server issue',
                                RideHistoryFailureKind.other =>
                                  'Could not load activity',
                              },
                              message: retryAutomatically
                                  ? '$message We’ll try again automatically.'
                                  : message,
                              icon:
                                  failureKind ==
                                      RideHistoryFailureKind.connection
                                  ? LucideIcons.wifi_off
                                  : LucideIcons.circle_alert,
                              actionLabel: retryAutomatically ? null : 'Retry',
                              onAction: retryAutomatically
                                  ? null
                                  : () => unawaited(_loadRideHistory()),
                              showBackButton: widget.showBackButton,
                              showSubtitle: widget.showHeaderSubtitle,
                            ),
                          RideHistoryLoaded(:final past, :final upcoming)
                              when past.isEmpty && upcoming.isEmpty =>
                            _RideHistoryMessageView(
                              headerTitle: widget.title,
                              subtitle: widget.subtitle,
                              title: 'No rides yet',
                              message: 'Your completed and cancelled rides will appear here.',
                              showBackButton: widget.showBackButton,
                              showSubtitle: widget.showHeaderSubtitle,
                            ),
                          RideHistoryLoaded(
                            :final past,
                            :final upcoming,
                            :final hasMore,
                            :final isLoadingMore,
                            :final loadMoreError,
                            :final weeklyFareAmount,
                            :final weeklyRideCount,
                          ) =>
                            RideHistoryListView(
                              headerTitle: widget.title,
                              headerSubtitle: widget.subtitle,
                              showBackButton: widget.showBackButton,
                              showHeaderSubtitle: widget.showHeaderSubtitle,
                              showSummary: widget.showSummary,
                              showFilters: widget.showFilters,
                              activeRides: upcoming,
                              pastRides: past,
                              referenceTime: DateTime.now(),
                              onRideTap: _openRide,
                              hasMore: hasMore,
                              isLoadingMore: isLoadingMore,
                              loadMoreError: loadMoreError,
                              onLoadMore: _loadMoreRideHistory,
                              weeklyFare: weeklyFareAmount / 100,
                              weeklyRideCount: weeklyRideCount,
                            ),
                        },
                      ),
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadRideHistory() async {
    final sessionState = BlocProvider.of<SessionBloc>(context).state;
    if (sessionState case AuthenticatedSession(:final passengerId)) {
      BlocProvider.of<RideHistoryBloc>(context)
          .add(LoadRideHistoryEvent(passengerId: passengerId));
    }
  }

  void _loadMoreRideHistory() {
    final sessionState = BlocProvider.of<SessionBloc>(context).state;
    if (sessionState case AuthenticatedSession(:final passengerId)) {
      BlocProvider.of<RideHistoryBloc>(context)
          .add(LoadMoreRideHistoryEvent(passengerId: passengerId));
    }
  }

  void _openRide(RideHistory ride) {
    switch (RideStatus.fromString(ride.status)) {
      case RideStatus.accepted || RideStatus.arrived || RideStatus.inTransit:
        unawaited(
          context.pushNamed(ActiveRideRoutes.trackDriver, extra: ride.id),
        );
      case RideStatus.completed || RideStatus.cancelled:
        unawaited(
          context.pushNamed(RideHistoryRoutes.rideDetails, extra: ride),
        );
      case RideStatus.requested || RideStatus.unknown:
        unawaited(context.pushNamed(BookingRoutes.searchDestination));
    }
  }
}

double _rideHistoryBottomClearance(BuildContext context) {
  return AppFloatingTabBar.height + MediaQuery.paddingOf(context).bottom + 10;
}

class _RideHistoryMessageView extends StatelessWidget {
  const _RideHistoryMessageView({
    required this.subtitle,
    required this.title,
    required this.message,
    this.headerTitle = 'Activity',
    this.showBackButton = false,
    this.showSubtitle = true,
    this.icon = LucideIcons.route,
    this.actionLabel,
    this.onAction,
  });
  final String subtitle;
  final String title;
  final String message;
  final String headerTitle;
  final bool showBackButton;
  final bool showSubtitle;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final horizontalPadding = MediaQuery.sizeOf(context).width < 360
        ? AppLayout.pagePadding
        : AppLayout.pagePaddingWide;
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
          sliver: SliverToBoxAdapter(
            child: RideHistoryHeader(
              title: headerTitle,
              subtitle: showSubtitle ? subtitle : null,
              showBackButton: showBackButton,
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              32,
              24,
              32,
              _rideHistoryBottomClearance(context),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon case final icon?) ...[
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLowest,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 24, color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: context.textStyles.titleMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  TextButton.icon(
                    onPressed: onAction,
                    style:
                        TextButton.styleFrom(
                          foregroundColor: colors.onSurface,
                          enableFeedback: false,
                          splashFactory: NoSplash.splashFactory,
                          minimumSize: const Size(
                            0,
                            AppSize.minimumTouchTarget,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ).copyWith(
                          overlayColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.focused)
                                ? colors.primary.withValues(alpha: 0.12)
                                : Colors.transparent,
                          ),
                        ),
                    icon: const Icon(LucideIcons.refresh_cw, size: 16),
                    label: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RideHistoryLoadingView extends StatelessWidget {
  const _RideHistoryLoadingView({
    required this.itemCount,
    this.title = 'Activity',
    this.subtitle = 'Tap a ride to see details',
    this.showBackButton = false,
    this.showSubtitle = true,
    this.showSummary = true,
    this.showFilters = true,
  });
  final int itemCount;
  final String title;
  final String subtitle;
  final bool showBackButton;
  final bool showSubtitle;
  final bool showSummary;
  final bool showFilters;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = MediaQuery.sizeOf(context).width < 360
        ? AppLayout.pagePadding
        : AppLayout.pagePaddingWide;
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
          sliver: SliverToBoxAdapter(
            child: RideHistoryHeader(
              title: title,
              subtitle: showSubtitle ? subtitle : null,
              showBackButton: showBackButton,
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          sliver: Skeletonizer.sliver(
            key: const ValueKey<String>('activity-loading-skeleton'),
            child: SliverList(
              delegate: SliverChildListDelegate([
                if (showSummary) ...[
                  const KeyedSubtree(
                    key: ValueKey<String>('activity-loading-summary'),
                    child: _ActivitySkeletonSummary(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (showFilters) ...[
                  const KeyedSubtree(
                    key: ValueKey<String>('activity-loading-filters'),
                    child: _ActivitySkeletonFilters(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                for (var index = 0; index < itemCount; index++) ...[
                  if (index == 0) ...[
                    const Bone.text(width: 92, fontSize: 12),
                    const SizedBox(height: AppSpacing.xs),
                  ] else
                    Divider(
                      height: 1,
                      indent: 54,
                      color: context.colorScheme.outlineVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  const _ActivitySkeletonRideRow(),
                ],
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(height: _rideHistoryBottomClearance(context)),
        ),
      ],
    );
  }
}

class _ActivitySkeletonSummary extends StatelessWidget {
  const _ActivitySkeletonSummary();

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            const Expanded(child: _ActivitySkeletonMetric(valueWidth: 68)),
            VerticalDivider(
              width: 1,
              thickness: 1,
              indent: AppSpacing.md,
              endIndent: AppSpacing.md,
              color: colors.outlineVariant.withValues(alpha: 0.7),
            ),
            const Expanded(child: _ActivitySkeletonMetric(valueWidth: 30)),
          ],
        ),
      ),
    );
  }
}

class _ActivitySkeletonMetric extends StatelessWidget {
  const _ActivitySkeletonMetric({required this.valueWidth});

  final double valueWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Bone.text(width: 68, fontSize: 12),
          const SizedBox(height: AppSpacing.xs),
          Bone.text(width: valueWidth, fontSize: 22),
        ],
      ),
    );
  }
}

class _ActivitySkeletonFilters extends StatelessWidget {
  const _ActivitySkeletonFilters();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
      child: const SizedBox(
        height: AppSize.minimumTouchTarget,
        child: Row(
          children: [
            Expanded(child: Center(child: Bone.text(width: 32, fontSize: 14))),
            Expanded(child: Center(child: Bone.text(width: 72, fontSize: 14))),
            Expanded(child: Center(child: Bone.text(width: 68, fontSize: 14))),
          ],
        ),
      ),
    );
  }
}

class _ActivitySkeletonRideRow extends StatelessWidget {
  const _ActivitySkeletonRideRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Bone.circle(size: 40),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(width: 146, fontSize: 15),
                SizedBox(height: 4),
                Bone.text(width: 104, fontSize: 13),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Bone.text(width: 48, fontSize: 14),
          SizedBox(width: AppSpacing.xs),
          Bone.icon(size: 16),
        ],
      ),
    );
  }
}

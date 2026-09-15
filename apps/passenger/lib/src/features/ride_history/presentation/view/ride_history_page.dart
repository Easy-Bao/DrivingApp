import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/active_ride/active_ride_routes.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/booking/booking_routes.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_history/ride_history_bloc.dart';
import 'package:passenger/src/features/ride_history/presentation/widgets/ride_history_header_widget.dart';
import 'package:passenger/src/features/ride_history/presentation/widgets/ride_history_widget.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';
import 'package:passenger/src/features/ride_history/ride_history_routes.dart';
import 'package:skeletonizer/skeletonizer.dart';

class const RideHistoryPage({
  this.title = 'Activity',
  this.subtitle = 'Tap a ride to see details',
  this.showBackButton = false,
  this.showHeaderSubtitle = true,
  this.showSummary = true,
  this.showFilters = true,
  super.key,
}) extends StatefulWidget {
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
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: context.colorScheme.onSurface,
          onRefresh: _loadRideHistory,
          child: BlocListener<SessionBloc, SessionState>(
            listenWhen: (_, current) => current is AuthenticatedSession,
            listener: (_, _) => unawaited(_loadRideHistory()),
            child: BlocBuilder<SessionBloc, SessionState>(
              builder: (context, sessionState) => switch (sessionState) {
                SessionLoading() => _RideHistoryProgressView(
                  title: widget.title,
                  subtitle: 'Checking your account',
                  showBackButton: widget.showBackButton,
                  showSubtitle: widget.showHeaderSubtitle,
                ),
                GuestSession() || SessionFailure() => _RideHistoryMessageView(
                  headerTitle: widget.title,
                  subtitle: 'Sign in to view your ride history',
                  title: 'Guest mode',
                  message: 'Sign in to see your recent trips.',
                  showBackButton: widget.showBackButton,
                  showSubtitle: widget.showHeaderSubtitle,
                ),
                AuthenticatedSession() =>
                  BlocBuilder<RideHistoryBloc, RideHistoryState>(
                    builder: (context, state) => switch (state) {
                      RideHistoryInitial() => _RideHistoryProgressView(
                        title: widget.title,
                        subtitle: 'Preparing your activity',
                        showBackButton: widget.showBackButton,
                        showSubtitle: widget.showHeaderSubtitle,
                      ),
                      RideHistoryLoading(:final existingRideCount)
                          when existingRideCount > 0 =>
                        _RideHistoryLoadingView(
                          title: widget.title,
                          subtitle: widget.subtitle,
                          showBackButton: widget.showBackButton,
                          showSubtitle: widget.showHeaderSubtitle,
                          itemCount: existingRideCount
                              .clamp(
                                _defaultSkeletonCount,
                                _maximumSkeletonCount,
                              )
                              .toInt(),
                        ),
                      RideHistoryLoading() => _RideHistoryProgressView(
                        title: widget.title,
                        subtitle: 'Loading your activity',
                        showBackButton: widget.showBackButton,
                        showSubtitle: widget.showHeaderSubtitle,
                      ),
                      RideHistoryError(:final message) =>
                        _RideHistoryMessageView(
                          headerTitle: widget.title,
                          subtitle: widget.subtitle,
                          title: 'Could not load activity',
                          message: message,
                          icon: LucideIcons.wifi_off,
                          actionLabel: 'Retry',
                          onAction: _loadRideHistory,
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
                        RideHistoryWidget(
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
        unawaited(context.pushNamed(ActiveRideRoutes.trackDriver, extra: ride));
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

class const _RideHistoryProgressView({
  required this.subtitle,
  this.showBackButton = false,
  this.showSubtitle = true,
  this.title = 'Activity',
}) extends StatelessWidget {
  final String subtitle;
  final bool showBackButton;
  final bool showSubtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            EasyRideLayout.pagePadding,
            8,
            EasyRideLayout.pagePadding,
            18,
          ),
          sliver: SliverToBoxAdapter(
            child: RideHistoryHeaderWidget(
              title: title,
              subtitle: showSubtitle ? subtitle : null,
              showBackButton: showBackButton,
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 32,
              top: 24,
              right: 32,
              bottom: _rideHistoryBottomClearance(context),
            ),
            child: Center(
              child: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class const _RideHistoryMessageView({
  required this.subtitle,
  required this.title,
  required this.message,
  this.headerTitle = 'Activity',
  this.showBackButton = false,
  this.showSubtitle = true,
  this.icon = LucideIcons.route,
  this.actionLabel,
  this.onAction,
}) extends StatelessWidget {
  final String subtitle;
  final String title;
  final String message;
  final String headerTitle;
  final bool showBackButton;
  final bool showSubtitle;
  final IconData icon;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            EasyRideLayout.pagePadding,
            8,
            EasyRideLayout.pagePadding,
            18,
          ),
          sliver: SliverToBoxAdapter(
            child: RideHistoryHeaderWidget(
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
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 30,
                    color: context.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: context.textStyles.titleLarge?.copyWith(
                    color: context.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onAction,
                    icon: const Icon(LucideIcons.refresh_cw, size: 16),
                    label: Text(actionLabel!),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.colorScheme.onSurface,
                      foregroundColor: context.colorScheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          EasyRideRadius.pill,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
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

class const _RideHistoryLoadingView({
  required this.itemCount,
  this.title = 'Activity',
  this.subtitle = 'Tap a ride to see details',
  this.showBackButton = false,
  this.showSubtitle = true,
}) extends StatelessWidget {
  final int itemCount;
  final String title;
  final String subtitle;
  final bool showBackButton;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            EasyRideLayout.pagePadding,
            8,
            EasyRideLayout.pagePadding,
            18,
          ),
          sliver: SliverToBoxAdapter(
            child: RideHistoryHeaderWidget(
              title: title,
              subtitle: showSubtitle ? subtitle : null,
              showBackButton: showBackButton,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: EasyRideLayout.pagePadding,
          ),
          sliver: Skeletonizer.sliver(
            key: const ValueKey<String>('activity-loading-skeleton'),
            child: SliverList(
              delegate: SliverChildListDelegate([
                const _ActivitySkeletonSummary(),
                const SizedBox(height: 14),
                const _ActivitySkeletonFilters(),
                const SizedBox(height: 18),
                for (var index = 0; index < itemCount; index++) ...[
                  if (index == 0) ...[
                    const Bone.text(width: 92, fontSize: 12),
                    const SizedBox(height: 8),
                  ],
                  const _ActivitySkeletonRideCard(),
                  const SizedBox(height: 8),
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

class const _ActivitySkeletonSummary() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _ActivitySkeletonSummaryCard(valueWidth: 64)),
        SizedBox(width: 8),
        Expanded(child: _ActivitySkeletonSummaryCard(valueWidth: 28)),
      ],
    );
  }
}

class const _ActivitySkeletonSummaryCard({required this.valueWidth})
    extends StatelessWidget {
  final double valueWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Bone.text(width: 72, fontSize: 14),
          const SizedBox(height: 4),
          Bone.text(width: valueWidth, fontSize: 22),
        ],
      ),
    );
  }
}

class const _ActivitySkeletonFilters() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Bone.button(
          width: 48,
          height: 38,
          borderRadius: BorderRadius.all(Radius.circular(EasyRideRadius.lg)),
        ),
        SizedBox(width: 8),
        Bone.button(
          width: 88,
          height: 38,
          borderRadius: BorderRadius.all(Radius.circular(EasyRideRadius.lg)),
        ),
        SizedBox(width: 8),
        Bone.button(
          width: 84,
          height: 38,
          borderRadius: BorderRadius.all(Radius.circular(EasyRideRadius.lg)),
        ),
      ],
    );
  }
}

class const _ActivitySkeletonRideCard() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Bone.circle(size: 42),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(width: 146, fontSize: 16),
                SizedBox(height: 4),
                Bone.text(width: 104, fontSize: 14),
              ],
            ),
          ),
          SizedBox(width: 8),
          Bone.text(width: 48, fontSize: 15),
          SizedBox(width: 3),
          Bone.icon(size: 18),
        ],
      ),
    );
  }
}

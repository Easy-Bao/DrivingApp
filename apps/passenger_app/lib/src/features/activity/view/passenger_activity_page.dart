import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/activity/activity_routes.dart';
import 'package:passenger_app/src/features/activity/bloc/activity/activity_bloc.dart';
import 'package:passenger_app/src/features/activity/view/widgets/passenger_activity_header_widget.dart';
import 'package:passenger_app/src/features/activity/view/widgets/passenger_activity_history_widget.dart';
import 'package:passenger_app/src/features/auth/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/trip/trip_routes.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PassengerActivityPage extends StatefulWidget {
  const PassengerActivityPage({super.key});

  @override
  State<PassengerActivityPage> createState() => _PassengerActivityPageState();
}

class _PassengerActivityPageState extends State<PassengerActivityPage> {
  static const int _defaultSkeletonCount = 4;
  static const int _maximumSkeletonCount = 6;

  bool _hasLoadedActivity = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasLoadedActivity) return;
    _hasLoadedActivity = true;
    unawaited(_loadActivity());
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = context.select<SessionBloc, bool>((bloc) {
      final sessionState = bloc.state;
      return sessionState is GuestSession || sessionState is SessionFailure;
    });

    return Scaffold(
      backgroundColor: context.canvasColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: context.colorScheme.onSurface,
          onRefresh: _loadActivity,
          child: isGuest
              ? const _ActivityMessageView(
                  subtitle: 'Sign in to view your ride history',
                  title: 'Guest mode',
                  message: 'Sign in to see your recent trips.',
                )
              : BlocBuilder<ActivityBloc, ActivityState>(
                  builder: (context, state) => switch (state) {
                    ActivityInitial() => const _ActivityLoadingView(
                      itemCount: _defaultSkeletonCount,
                    ),
                    ActivityLoading(:final existingRideCount) =>
                      _ActivityLoadingView(
                        itemCount: existingRideCount
                            .clamp(_defaultSkeletonCount, _maximumSkeletonCount)
                            .toInt(),
                      ),
                    ActivityError(:final message) => _ActivityMessageView(
                      subtitle: 'Tap a ride to see details',
                      title: 'Could not load activity',
                      message: message,
                      icon: LucideIcons.wifi_off,
                      actionLabel: 'Retry',
                      onAction: _loadActivity,
                    ),
                    ActivityLoaded(:final past, :final upcoming)
                        when past.isEmpty && upcoming.isEmpty =>
                      const _ActivityMessageView(
                        subtitle: 'Tap a ride to see details',
                        title: 'No rides yet',
                        message:
                            'Your completed and cancelled rides will appear here.',
                      ),
                    ActivityLoaded(
                      :final past,
                      :final upcoming,
                      :final hasMore,
                      :final isLoadingMore,
                      :final loadMoreError,
                      :final weeklyFareCentavos,
                      :final weeklyRideCount,
                    ) =>
                      PassengerActivityHistoryWidget(
                        activeRides: upcoming,
                        pastRides: past,
                        referenceTime: DateTime.now(),
                        onRideTap: _openRide,
                        hasMore: hasMore,
                        isLoadingMore: isLoadingMore,
                        loadMoreError: loadMoreError,
                        onLoadMore: _loadMoreActivity,
                        weeklyFare: weeklyFareCentavos / 100,
                        weeklyRideCount: weeklyRideCount,
                      ),
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _loadActivity() async {
    final sessionState = BlocProvider.of<SessionBloc>(context).state;
    if (sessionState case AuthenticatedSession(:final passengerId)) {
      BlocProvider.of<ActivityBloc>(
        context,
      ).add(LoadActivityEvent(passengerId: passengerId));
    }
  }

  void _loadMoreActivity() {
    final sessionState = BlocProvider.of<SessionBloc>(context).state;
    if (sessionState case AuthenticatedSession(:final passengerId)) {
      BlocProvider.of<ActivityBloc>(
        context,
      ).add(LoadMoreActivityEvent(passengerId: passengerId));
    }
  }

  void _openRide(RideHistoryModel ride) {
    switch (RideStatus.fromString(ride.status)) {
      case RideStatus.accepted || RideStatus.arrived || RideStatus.inTransit:
        unawaited(
          context.pushNamed(ActivityRoutes.activityTrackDriver, extra: ride),
        );
      case RideStatus.completed || RideStatus.cancelled:
        unawaited(
          context.pushNamed(ActivityRoutes.activityViewDetails, extra: ride),
        );
      case RideStatus.requested || RideStatus.unknown:
        unawaited(context.pushNamed(TripRoutes.searchDestination));
    }
  }
}

class _ActivityMessageView extends StatelessWidget {
  final String subtitle;
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  const _ActivityMessageView({
    required this.subtitle,
    required this.title,
    required this.message,
    this.icon = LucideIcons.route,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          sliver: SliverToBoxAdapter(
            child: PassengerActivityHeaderWidget(subtitle: subtitle),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 112),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 38,
                  color: context.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.45,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: context.colorScheme.onSurface,
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

class _ActivityLoadingView extends StatelessWidget {
  final int itemCount;

  const _ActivityLoadingView({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 18),
          sliver: SliverToBoxAdapter(
            child: PassengerActivityHeaderWidget(
              subtitle: 'Tap a ride to see details',
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: Skeletonizer.sliver(
            child: SliverList(
              delegate: SliverChildListDelegate([
                const Row(
                  children: [
                    Expanded(child: Bone(width: double.infinity, height: 78)),
                    SizedBox(width: 8),
                    Expanded(child: Bone(width: double.infinity, height: 78)),
                  ],
                ),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    Bone(width: 48, height: 30),
                    SizedBox(width: 8),
                    Bone(width: 88, height: 30),
                    SizedBox(width: 8),
                    Bone(width: 84, height: 30),
                  ],
                ),
                const SizedBox(height: 18),
                for (var index = 0; index < itemCount; index++) ...[
                  if (index == 0) ...[
                    const Bone.text(width: 92, fontSize: 12),
                    const SizedBox(height: 8),
                  ],
                  const Bone(width: double.infinity, height: 68),
                  const SizedBox(height: 8),
                ],
              ]),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 112)),
      ],
    );
  }
}

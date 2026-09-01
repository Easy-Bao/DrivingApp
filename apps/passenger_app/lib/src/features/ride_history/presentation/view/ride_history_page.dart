import 'package:passenger_app/src/features/active_ride/active_ride.dart';
import 'package:passenger_app/src/features/ride_history/ride_history.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/ride_history/ride_history_routes.dart';
import 'package:passenger_app/src/features/ride_history/presentation/bloc/ride_history/ride_history_bloc.dart';
import 'package:passenger_app/src/features/ride_history/presentation/widgets/ride_history_header_widget.dart';
import 'package:passenger_app/src/features/ride_history/presentation/widgets/ride_history_widget.dart';
import 'package:passenger_app/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/active_ride/active_ride_routes.dart';
import 'package:passenger_app/src/features/booking/booking_routes.dart';
import 'package:design_system/design_system.dart';
import 'package:skeletonizer/skeletonizer.dart';

class RideHistoryPage extends StatefulWidget {
  const RideHistoryPage({super.key});

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  static const int _defaultSkeletonCount = 4;
  static const int _maximumSkeletonCount = 6;

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
          onRefresh: _loadRideHistory,
          child: isGuest
              ? const _RideHistoryMessageView(
                  subtitle: 'Sign in to view your ride history',
                  title: 'Guest mode',
                  message: 'Sign in to see your recent trips.',
                )
              : BlocBuilder<RideHistoryBloc, RideHistoryState>(
                  builder: (context, state) => switch (state) {
                    RideHistoryInitial() => const _RideHistoryLoadingView(
                      itemCount: _defaultSkeletonCount,
                    ),
                    RideHistoryLoading(:final existingRideCount) =>
                      _RideHistoryLoadingView(
                        itemCount: existingRideCount
                            .clamp(_defaultSkeletonCount, _maximumSkeletonCount)
                            .toInt(),
                      ),
                    RideHistoryError(:final message) => _RideHistoryMessageView(
                      subtitle: 'Tap a ride to see details',
                      title: 'Could not load activity',
                      message: message,
                      icon: LucideIcons.wifi_off,
                      actionLabel: 'Retry',
                      onAction: _loadRideHistory,
                    ),
                    RideHistoryLoaded(:final past, :final upcoming)
                        when past.isEmpty && upcoming.isEmpty =>
                      const _RideHistoryMessageView(
                        subtitle: 'Tap a ride to see details',
                        title: 'No rides yet',
                        message: 'Your completed and cancelled rides will appear here.',
                      ),
                    RideHistoryLoaded(
                      :final past,
                      :final upcoming,
                      :final hasMore,
                      :final isLoadingMore,
                      :final loadMoreError,
                      :final weeklyFareCentavos,
                      :final weeklyRideCount,
                    ) =>
                      RideHistoryWidget(
                        activeRides: upcoming,
                        pastRides: past,
                        referenceTime: DateTime.now(),
                        onRideTap: _openRide,
                        hasMore: hasMore,
                        isLoadingMore: isLoadingMore,
                        loadMoreError: loadMoreError,
                        onLoadMore: _loadMoreRideHistory,
                        weeklyFare: weeklyFareCentavos / 100,
                        weeklyRideCount: weeklyRideCount,
                      ),
                  },
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

class _RideHistoryMessageView extends StatelessWidget {
  final String subtitle;
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  const _RideHistoryMessageView({
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
            child: RideHistoryHeaderWidget(subtitle: subtitle),
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
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: context.colorScheme.onSurfaceVariant),
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

class _RideHistoryLoadingView extends StatelessWidget {
  final int itemCount;

  const _RideHistoryLoadingView({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 18),
          sliver: SliverToBoxAdapter(
            child: RideHistoryHeaderWidget(
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

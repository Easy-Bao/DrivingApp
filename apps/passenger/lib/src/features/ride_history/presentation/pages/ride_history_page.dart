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
import 'package:passenger/src/features/ride_history/presentation/widgets/ride_history_list_view.dart';
import 'package:passenger/src/features/ride_history/presentation/widgets/ride_history_status_views.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';
import 'package:passenger/src/features/ride_history/ride_history_routes.dart';

class RideHistoryPage extends StatefulWidget {
  const RideHistoryPage({
    this.title = 'Activity',
    this.subtitle = 'Your trips and receipts',
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
  DateTime _referenceTime = DateTime.now();

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
          onRefresh: _refreshRideHistory,
          child: BlocListener<SessionBloc, SessionState>(
            listenWhen: (_, current) => current is AuthenticatedSession,
            listener: (_, _) => unawaited(_loadRideHistory()),
            child: BlocBuilder<SessionBloc, SessionState>(
              builder: (context, sessionState) => switch (sessionState) {
                SessionLoading() => RideHistoryLoadingView(
                  title: widget.title,
                  subtitle: 'Checking your account',
                  showBackButton: widget.showBackButton,
                  showSubtitle: widget.showHeaderSubtitle,
                  showSummary: widget.showSummary,
                  showFilters: widget.showFilters,
                  itemCount: _defaultSkeletonCount,
                ),
                GuestSession() || SessionFailure() => RideHistoryMessageView(
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
                      RideHistoryInitial() => RideHistoryLoadingView(
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
                        RideHistoryLoadingView(
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
                      RideHistoryLoading() => RideHistoryLoadingView(
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
                        RideHistoryMessageView(
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
                          icon: failureKind == RideHistoryFailureKind.connection
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
                        RideHistoryMessageView(
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
                          referenceTime: _referenceTime,
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
    _referenceTime = DateTime.now();
    final sessionState = BlocProvider.of<SessionBloc>(context).state;
    if (sessionState case AuthenticatedSession(:final passengerId)) {
      BlocProvider.of<RideHistoryBloc>(context)
          .add(LoadRideHistoryEvent(passengerId: passengerId));
    }
  }

  Future<void> _refreshRideHistory() async {
    _referenceTime = DateTime.now();
    final sessionState = BlocProvider.of<SessionBloc>(context).state;
    if (sessionState case AuthenticatedSession(:final passengerId)) {
      final bloc = BlocProvider.of<RideHistoryBloc>(context);
      final completer = Completer<void>();
      bloc.add(
        RefreshRideHistoryEvent(passengerId: passengerId, completer: completer),
      );
      await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {},
      );
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

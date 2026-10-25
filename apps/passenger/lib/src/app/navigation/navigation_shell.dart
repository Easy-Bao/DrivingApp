import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/app/navigation/floating_tab_bar.dart';
import 'package:passenger/src/app/navigation/guest_action_bar.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/active_ride_routes.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver_cubit.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver_state.dart';
import 'package:passenger/src/features/auth/auth_routes.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger/src/features/home/presentation/widgets/active_ride_banner.dart';
import 'package:passenger/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox_cubit.dart';
import 'package:passenger/src/features/profile/profile_routes.dart';

class TabBranchContainer extends StatelessWidget {
  const TabBranchContainer({
    super.key,
    required this.navigationShell,
    required this.children,
    required this.onNavigationSettled,
    required this.onPagePositionChanged,
    this.allowUserNavigation = true,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;
  final ValueChanged<int> onNavigationSettled;
  final ValueChanged<double> onPagePositionChanged;
  final bool allowUserNavigation;

  @override
  Widget build(BuildContext context) => AppTabBranchContainer(
    key: key,
    currentIndex: navigationShell.currentIndex,
    onBranchChanged: (index) => navigationShell.goBranch(index),
    onNavigationSettled: onNavigationSettled,
    onPagePositionChanged: onPagePositionChanged,
    allowUserNavigation: allowUserNavigation,
    backgroundColor: context.canvasColor,
    pageViewKey: 'passenger-tab-page-view',
    children: children,
  );
}

class ShellLayout extends StatefulWidget {
  const ShellLayout({
    super.key,
    required this.navigationShell,
    required this.inboxCubit,
    required this.realtimeClient,
    required this.lifecycleCoordinator,
    required this.navigationCoordinator,
    required this.bookingStates,
    this.trackDriverCubit,
  });
  final StatefulNavigationShell navigationShell;
  final InboxCubit inboxCubit;
  final RealtimeWebSocketClient realtimeClient;
  final AppLifecycleCoordinator lifecycleCoordinator;
  final TabNavigationCoordinator navigationCoordinator;
  final TrackDriverCubit? trackDriverCubit;
  final Stream<BookingState> bookingStates;

  @override
  State<ShellLayout> createState() => _ShellLayoutState();
}

class _ShellLayoutState extends State<ShellLayout> {
  String? _loadedInboxPassengerId;
  String? _activePassengerId;
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;
  late final StreamSubscription<BookingState> _bookingSubscription;
  late final StreamSubscription<AppLifecycleStatus> _lifecycleSubscription;
  bool _isForeground = true;
  bool _activityTabBarVisible = true;

  @override
  void initState() {
    super.initState();
    _isForeground = widget.lifecycleCoordinator.isForeground;
    _lifecycleSubscription = widget.lifecycleCoordinator.changes.listen(
      _onLifecycleChanged,
    );
    widget.navigationCoordinator.initialize(
      widget.navigationShell.currentIndex,
    );
    widget.navigationCoordinator.addListener(_onNavigationChanged);
    _realtimeSubscription = widget.realtimeClient.events.listen(
      _handleRealtimeEvent,
    );
    _bookingSubscription = widget.bookingStates.listen((state) {
      if (mounted && state is BookingFailure && state.isRequestExpired) {
        unawaited(_loadInboxNotifications(refresh: true));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _forceHomeForGuest();
        unawaited(_loadInboxNotifications());
      }
    });
  }

  @override
  void dispose() {
    widget.navigationCoordinator.removeListener(_onNavigationChanged);
    unawaited(_lifecycleSubscription.cancel());
    unawaited(_realtimeSubscription?.cancel());
    unawaited(_bookingSubscription.cancel());
    unawaited(widget.realtimeClient.stop());
    super.dispose();
  }

  void _onLifecycleChanged(AppLifecycleStatus status) {
    final isForeground = status == AppLifecycleStatus.foreground;
    if (!isForeground) {
      if (_isForeground) {
        _isForeground = false;
        unawaited(widget.realtimeClient.stop());
      }
      return;
    }

    if (_isForeground) return;
    _isForeground = true;
    if (_activePassengerId != null) {
      unawaited(_loadInboxNotifications(refresh: true));
    }
  }

  void _onNavigationChanged() {
    if (!mounted) return;
    setState(() => _activityTabBarVisible = true);
    if (widget.navigationCoordinator.selectedIndex == 2) {
      unawaited(_loadInboxNotifications(refresh: true));
    }
  }

  bool _onActivityScroll(ScrollNotification notification) {
    if (widget.navigationCoordinator.selectedIndex != 1 ||
        notification.metrics.axis != Axis.vertical ||
        MediaQuery.accessibleNavigationOf(context)) {
      return false;
    }
    bool? visible;
    if (notification.metrics.extentBefore <= 0) {
      visible = true;
    } else if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null &&
        notification.scrollDelta != null &&
        notification.scrollDelta != 0) {
      visible = notification.scrollDelta! < 0;
    } else if (notification is UserScrollNotification) {
      visible = switch (notification.direction) {
        ScrollDirection.forward => true,
        ScrollDirection.reverse when notification.metrics.maxScrollExtent > 0 =>
          false,
        _ => null,
      };
    }
    if (visible != null && visible != _activityTabBarVisible) {
      setState(() => _activityTabBarVisible = visible!);
    }
    return false;
  }

  Future<void> _loadInboxNotifications({bool refresh = false}) async {
    final sessionState = BlocProvider.of<SessionBloc>(context).state;
    if (sessionState is! AuthenticatedSession || widget.inboxCubit.isClosed) {
      return;
    }
    _activePassengerId = sessionState.passengerId;
    if (_isForeground) {
      unawaited(widget.realtimeClient.start());
    }
    if (!refresh && sessionState.passengerId == _loadedInboxPassengerId) return;
    _loadedInboxPassengerId = sessionState.passengerId;
    await widget.inboxCubit.loadNotifications(sessionState.passengerId);
  }

  void _handleRealtimeEvent(RealtimeEvent event) {
    if (!_isForeground) return;
    final passengerId = _activePassengerId;
    if (passengerId == null || event is! ChatMessageCreatedEvent) return;
    if (event.envelope.scope.passengerId != passengerId) return;
    final senderId = SafeParse.toStringValue(
      event.envelope.payload['sender_id'],
    );
    if (senderId.isEmpty || senderId == passengerId) return;
    final message = SafeParse.toStringValue(
      event.envelope.payload['text'],
      'You have a new message from your driver.',
    );
    final roomId = event.envelope.scope.roomId?.trim() ?? '';
    if (roomId.isEmpty) return;
    final receivedAt = event.envelope.occurredAt.toLocal();
    widget.inboxCubit.addLocalNotification(
      InboxNotification(
        id: event.envelope.id,
        title: 'New Message From Your Driver',
        message: message,
        timestamp: receivedAt,
        type: 'chat',
        isRead: false,
        roomId: roomId,
        userId: passengerId,
        peerId: senderId,
        peerName: 'Driver',
      ),
    );
  }

  String? _sessionErrorMessage;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.navigationCoordinator.selectedIndex;
    final isAuthenticated = context.select<SessionBloc, bool>(
      (bloc) => bloc.state.isAuthenticated,
    );
    final isWide = MediaQuery.sizeOf(context).width >= AppLayout.wideBreakpoint;
    return BlocListener<SessionBloc, SessionState>(
      listenWhen: (_, current) =>
          current is AuthenticatedSession ||
          current is GuestSession ||
          current is SessionFailure,
      listener: (_, state) {
        switch (state) {
          case AuthenticatedSession():
            if (_sessionErrorMessage != null) {
              setState(() => _sessionErrorMessage = null);
            }
            unawaited(_loadInboxNotifications());
          case SessionFailure(:final message):
            _forceHomeForGuest();
            _loadedInboxPassengerId = null;
            _activePassengerId = null;
            unawaited(widget.realtimeClient.stop());
            if (!widget.inboxCubit.isClosed) {
              widget.inboxCubit.clearSessionData();
            }
            setState(() => _sessionErrorMessage = message);
          case GuestSession():
            _forceHomeForGuest();
            _loadedInboxPassengerId = null;
            _activePassengerId = null;
            unawaited(widget.realtimeClient.stop());
            if (!widget.inboxCubit.isClosed) {
              widget.inboxCubit.clearSessionData();
            }
          case SessionLoading():
            break;
        }
      },
      child: PopScope(
        canPop: widget.navigationCoordinator.canPop,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          final previousIndex = widget.navigationCoordinator
              .goBackToPreviousTab();
          widget.navigationShell.goBranch(previousIndex);
        },
        child: Column(
          children: [
            if (_sessionErrorMessage != null)
              AppStatusBanner(
                isVisible: true,
                message: _sessionErrorMessage!,
                tone: AppStatusBannerTone.error,
                actionLabel: 'Dismiss',
                onAction: () => setState(() => _sessionErrorMessage = null),
              ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop:
                    _sessionErrorMessage != null &&
                    !AppNetworkStatusScope.isUnavailableOf(context),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Scaffold(
                      extendBody: true,
                      body: NotificationListener<ScrollNotification>(
                        onNotification: _onActivityScroll,
                        child: isWide && isAuthenticated
                            ? Row(
                                children: [
                                  ShellNavigationRail(
                                    selectedIndex: selectedIndex,
                                    onDestinationSelected: _onItemTapped,
                                    inboxCubit: widget.inboxCubit,
                                  ),
                                  const VerticalDivider(width: 1),
                                  Expanded(child: widget.navigationShell),
                                ],
                              )
                            : widget.navigationShell,
                      ),
                      bottomNavigationBar:
                          BlocSelector<SessionBloc, SessionState, bool>(
                            selector: (state) => state.isAuthenticated,
                            builder: (context, isAuthenticated) {
                              if (!isAuthenticated) {
                                return GuestActionBar(
                                  onSignUp: () =>
                                      context.pushNamed(AuthRoutes.signup),
                                  onSignIn: () =>
                                      context.pushNamed(AuthRoutes.signin),
                                  onHelp: () => context.pushNamed(
                                    ProfileRoutes.helpCenter,
                                  ),
                                );
                              }
                              if (isWide) return const SizedBox.shrink();
                              final bottomPadding = MediaQuery.of(context)
                                  .padding
                                  .bottom;
                              final trackCubit = _resolveTrackDriverCubit(
                                context,
                              );

                              Widget floatingTabBar = FloatingTabBar(
                                selectedIndex: selectedIndex,
                                onDestinationSelected: _onItemTapped,
                                inboxCubit: widget.inboxCubit,
                                pagePosition:
                                    widget.navigationCoordinator.pagePosition,
                              );

                              if (trackCubit != null) {
                                floatingTabBar =
                                    BlocBuilder<
                                      TrackDriverCubit,
                                      TrackDriverState
                                    >(
                                      bloc: trackCubit,
                                      builder: (context, trackState) {
                                        return FloatingTabBar(
                                          selectedIndex: selectedIndex,
                                          onDestinationSelected: _onItemTapped,
                                          inboxCubit: widget.inboxCubit,
                                          pagePosition: widget
                                              .navigationCoordinator
                                              .pagePosition,
                                          activeRideBanner:
                                              _buildActiveRideBannerForTabBar(
                                                context,
                                                trackState,
                                              ),
                                        );
                                      },
                                    );
                              }

                              final visible =
                                  selectedIndex != 1 ||
                                  _activityTabBarVisible ||
                                  MediaQuery.accessibleNavigationOf(context);
                              return ExcludeSemantics(
                                excluding: !visible,
                                child: IgnorePointer(
                                  ignoring: !visible,
                                  child: AnimatedSlide(
                                    key: const ValueKey(
                                      'passenger-tab-bar-visibility',
                                    ),
                                    offset: visible
                                        ? Offset.zero
                                        : const Offset(0, 1),
                                    duration:
                                        MediaQuery.disableAnimationsOf(context)
                                        ? Duration.zero
                                        : const Duration(milliseconds: 180),
                                    curve: Curves.easeOutCubic,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        bottom: bottomPadding + 10,
                                      ),
                                      child: FractionallySizedBox(
                                        widthFactor: 0.86,
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 440,
                                          ),
                                          child: floatingTabBar,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TrackDriverCubit? _resolveTrackDriverCubit(BuildContext context) {
    if (widget.trackDriverCubit != null) return widget.trackDriverCubit;
    try {
      return BlocProvider.of<TrackDriverCubit>(context);
    } catch (_) {
      try {
        return Modular.get<TrackDriverCubit>();
      } catch (_) {
        return null;
      }
    }
  }

  Widget? _buildActiveRideBannerForTabBar(
    BuildContext context,
    TrackDriverState trackState,
  ) {
    if (trackState.isTerminal || !trackState.isTracking) return null;

    final statusText = trackState.isInTransit
        ? 'Heading to Destination'
        : trackState.hasArrived
        ? 'Driver Has Arrived'
        : 'Driver is Picking You Up';

    return ActiveRideBanner(
      statusText: statusText,
      driverName: trackState.activeDriverName.isNotEmpty
          ? trackState.activeDriverName
          : 'Driver',
      vehicleInfo: [
        trackState.activeVehicleType,
        trackState.activeVehiclePlate,
      ].where((v) => v.trim().isNotEmpty).join(' • '),
      onResume: () => unawaited(_resumeFromShell()),
    );
  }

  Future<void> _resumeFromShell() async {
    if (!mounted) return;
    SessionStore? session;
    try {
      session = Modular.get<SessionStore>();
    } catch (_) {}
    String? activeRideId;
    try {
      activeRideId = await session?.readActiveRideId();
    } catch (_) {}
    if (!mounted) return;
    if (activeRideId != null && activeRideId.trim().isNotEmpty) {
      unawaited(
        context.pushNamed(
          ActiveRideRoutes.trackDriver,
          extra: activeRideId.trim(),
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    if (!BlocProvider.of<SessionBloc>(context).state.isAuthenticated) {
      _forceHomeForGuest();
      return;
    }
    if (widget.navigationCoordinator.selectedIndex == index) return;
    widget.navigationCoordinator.commit(index);
    widget.navigationShell.goBranch(index);
  }

  void _forceHomeForGuest() {
    if (!mounted ||
        BlocProvider.of<SessionBloc>(context).state.isAuthenticated ||
        widget.navigationShell.currentIndex == 0) {
      return;
    }
    widget.navigationCoordinator.commit(0);
    widget.navigationShell.goBranch(0);
  }
}

import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/app/navigation/floating_tab_bar.dart';
import 'package:passenger/src/app/navigation/guest_action_bar.dart';
import 'package:passenger/src/app/navigation/guest_help_bottom_sheet.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/active_ride_routes.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver_cubit.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver_state.dart';
import 'package:passenger/src/features/auth/auth_routes.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/booking/booking_routes.dart';
import 'package:passenger/src/features/booking/domain/entities/booking_draft.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:passenger/src/features/booking/presentation/widgets/cancel_booking_dialog.dart';
import 'package:passenger/src/features/home/presentation/widgets/active_booking_banner.dart';
import 'package:passenger/src/features/home/presentation/widgets/active_ride_banner.dart';
import 'package:passenger/src/features/home/presentation/widgets/pending_booking_banner.dart';
import 'package:passenger/src/features/inbox/domain/entities/inbox_notification.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox_cubit.dart';
import 'package:passenger/src/features/settings/settings_routes.dart';

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
    this.bookingBloc,
    this.bookingDraftCubit,
    this.trackDriverCubit,
  });
  final StatefulNavigationShell navigationShell;
  final InboxCubit inboxCubit;
  final RealtimeWebSocketClient realtimeClient;
  final AppLifecycleCoordinator lifecycleCoordinator;
  final TabNavigationCoordinator navigationCoordinator;
  final BookingBloc? bookingBloc;
  final BookingDraftCubit? bookingDraftCubit;
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
  bool _isContinuingBookingDraft = false;
  bool _isConfirmingBookingCancel = false;
  BookingFailure? _dismissedBookingFailure;

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
    _bookingSubscription = (widget.bookingBloc?.stream ?? widget.bookingStates)
        .listen(_handleBookingStateChanged);
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

  void _handleBookingStateChanged(BookingState state) {
    if (!mounted) return;
    if (state is BookingFailure && state.isNoDriverOrTimedOutFailure) {
      if (_dismissedBookingFailure != null || !_activityTabBarVisible) {
        setState(() {
          _dismissedBookingFailure = null;
          _activityTabBarVisible = true;
        });
      }
      unawaited(_loadInboxNotifications(refresh: true));
      return;
    }
    if (state is BookingFindingNearbyDrivers ||
        state is BookingSearching ||
        state is BookingOffersReceived ||
        state is BookingDriverMatched ||
        state is BookingRideRecovered) {
      if (_dismissedBookingFailure != null || !_activityTabBarVisible) {
        setState(() {
          _dismissedBookingFailure = null;
          _activityTabBarVisible = true;
        });
      }
    }
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
        MediaQuery.accessibleNavigationOf(context)) {
      return false;
    }
    if (notification.metrics.axis == Axis.horizontal) {
      if (notification is ScrollStartNotification &&
          notification.dragDetails != null &&
          !_activityTabBarVisible) {
        setState(() => _activityTabBarVisible = true);
      }
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
            unawaited(_loadInboxNotifications());
          case SessionFailure(:final message):
            _forceHomeForGuest();
            _loadedInboxPassengerId = null;
            _activePassengerId = null;
            unawaited(widget.realtimeClient.stop());
            if (!widget.inboxCubit.isClosed) {
              widget.inboxCubit.clearSessionData();
            }
            AppSnackBar.show(context, message, isError: true);
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
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: false,
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
                                  onHelp: () =>
                                      unawaited(_openGuestHelp(context)),
                                );
                              }
                              if (isWide) return const SizedBox.shrink();
                              final bottomPadding = MediaQuery.of(context)
                                  .padding
                                  .bottom;
                              final trackCubit = _resolveTrackDriverCubit(
                                context,
                              );
                              final bookingBloc = _resolveBookingBloc(context);
                              final bookingDraftCubit =
                                  _resolveBookingDraftCubit(context);

                              final floatingTabBar = _buildFloatingTabBar(
                                context,
                                selectedIndex: selectedIndex,
                                trackCubit: trackCubit,
                                bookingBloc: bookingBloc,
                                bookingDraftCubit: bookingDraftCubit,
                              );

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
                                        : Duration(
                                            milliseconds: visible ? 120 : 180,
                                          ),
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

  Future<void> _openGuestHelp(BuildContext context) async {
    final action = await showGuestHelpBottomSheet(context);
    if (!context.mounted || action == null) return;
    switch (action) {
      case GuestHelpAction.resetPassword:
        unawaited(context.pushNamed(AuthRoutes.forgotPassword));
      case GuestHelpAction.termsOfService:
        unawaited(context.pushNamed(SettingsRoutes.terms));
    }
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

  BookingBloc? _resolveBookingBloc(BuildContext context) {
    if (widget.bookingBloc != null) return widget.bookingBloc;
    try {
      return BlocProvider.of<BookingBloc>(context);
    } catch (_) {
      try {
        return Modular.get<BookingBloc>();
      } catch (_) {
        return null;
      }
    }
  }

  BookingDraftCubit? _resolveBookingDraftCubit(BuildContext context) {
    if (widget.bookingDraftCubit != null) return widget.bookingDraftCubit;
    try {
      return BlocProvider.of<BookingDraftCubit>(context);
    } catch (_) {
      try {
        return Modular.get<BookingDraftCubit>();
      } catch (_) {
        return null;
      }
    }
  }

  Widget _buildFloatingTabBar(
    BuildContext context, {
    required int selectedIndex,
    required TrackDriverCubit? trackCubit,
    required BookingBloc? bookingBloc,
    required BookingDraftCubit? bookingDraftCubit,
  }) {
    Widget buildBar({
      TrackDriverState? trackState,
      BookingState? bookingState,
      BookingDraft? draft,
    }) {
      final Widget? banner =
          (trackState != null
              ? _buildActiveRideBannerForTabBar(context, trackState)
              : null) ??
          (bookingBloc != null && bookingState != null
              ? _buildActiveBookingBannerForTabBar(
                  context,
                  bookingBloc,
                  bookingState,
                )
              : null) ??
          (bookingDraftCubit != null && draft != null
              ? _buildPendingBookingBannerForTabBar(
                  context,
                  draft: draft,
                  draftCubit: bookingDraftCubit,
                  trackState: trackState,
                  bookingBloc: bookingBloc,
                )
              : null);
      return FloatingTabBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _onItemTapped,
        inboxCubit: widget.inboxCubit,
        pagePosition: widget.navigationCoordinator.pagePosition,
        activeRideBanner: banner,
      );
    }

    Widget withDraft({
      TrackDriverState? trackState,
      BookingState? bookingState,
    }) {
      if (bookingDraftCubit == null) {
        return buildBar(trackState: trackState, bookingState: bookingState);
      }
      return BlocBuilder<BookingDraftCubit, BookingDraftState>(
        bloc: bookingDraftCubit,
        buildWhen: (previous, current) => previous.draft != current.draft,
        builder: (context, draftState) => buildBar(
          trackState: trackState,
          bookingState: bookingState,
          draft: draftState.draft,
        ),
      );
    }

    Widget withBooking({TrackDriverState? trackState}) {
      if (bookingBloc == null) return withDraft(trackState: trackState);
      return BlocBuilder<BookingBloc, BookingState>(
        bloc: bookingBloc,
        builder: (context, bookingState) =>
            withDraft(trackState: trackState, bookingState: bookingState),
      );
    }

    if (trackCubit == null) return withBooking();
    return BlocBuilder<TrackDriverCubit, TrackDriverState>(
      bloc: trackCubit,
      builder: (context, trackState) => withBooking(trackState: trackState),
    );
  }

  Widget? _buildPendingBookingBannerForTabBar(
    BuildContext context, {
    required BookingDraft draft,
    required BookingDraftCubit draftCubit,
    required TrackDriverState? trackState,
    required BookingBloc? bookingBloc,
  }) {
    if (trackState != null && !trackState.isTerminal && trackState.isTracking) {
      return null;
    }
    if (bookingBloc != null &&
        (bookingBloc.state.isBlockingBooking ||
            bookingBloc.hasActiveDriverSearch)) {
      return null;
    }
    return PendingBookingBanner(
      isAuthenticated: true,
      destinationName: draft.destination.name,
      onContinue: () => unawaited(
        _continuePendingBookingFromShell(
          draft,
          draftCubit,
          trackState: trackState,
          bookingBloc: bookingBloc,
        ),
      ),
      onDismiss: draftCubit.clear,
    );
  }

  Future<void> _continuePendingBookingFromShell(
    BookingDraft draft,
    BookingDraftCubit draftCubit, {
    required TrackDriverState? trackState,
    required BookingBloc? bookingBloc,
  }) async {
    if (!mounted || _isContinuingBookingDraft) return;
    if (trackState != null && !trackState.isTerminal && trackState.isTracking) {
      return;
    }
    if (bookingBloc != null &&
        (bookingBloc.state.isBlockingBooking ||
            bookingBloc.hasActiveDriverSearch)) {
      return;
    }
    _isContinuingBookingDraft = true;
    try {
      final pickupAddress = draft.pickupAddress;
      final position = LocationService.lastPosition;
      draftCubit.clear();
      await context.pushNamed(
        BookingRoutes.rideSelection,
        extra: {
          'destination': draft.destination,
          'tipAmount': draft.tipAmount,
          'notes': draft.notes,
        },
        queryParameters: {
          if (pickupAddress != null && pickupAddress.isNotEmpty)
            'pickupAddress': pickupAddress,
          if (position != null) ...{
            'pickupLat': position.latitude.toString(),
            'pickupLng': position.longitude.toString(),
          },
        },
      );
    } finally {
      _isContinuingBookingDraft = false;
    }
  }

  Widget? _buildActiveBookingBannerForTabBar(
    BuildContext context,
    BookingBloc bookingBloc,
    BookingState state,
  ) {
    final activeSearch = bookingBloc.activeDriverSearch;
    switch (state) {
      case BookingInitial() || BookingCanceled():
        return null;
      case BookingDriverMatched(:final matchResult, :final rideId):
        return ActiveBookingBanner(
          title: 'Driver accepted',
          subtitle: '${matchResult.driverName} is on the way',
          tone: ActiveBookingBannerTone.matched,
          icon: LucideIcons.car,
          actionLabel: 'Resume Trip',
          showActionArrow: true,
          onAction: () => unawaited(_resumeMatchedRideFromShell(rideId)),
        );
      case BookingRideRecovered(:final rideId):
        return ActiveBookingBanner(
          title: 'Driver accepted',
          subtitle: 'Resume your trip to track your driver.',
          tone: ActiveBookingBannerTone.matched,
          icon: LucideIcons.car,
          actionLabel: 'Resume Trip',
          showActionArrow: true,
          onAction: () => unawaited(_resumeMatchedRideFromShell(rideId)),
        );
      case BookingSessionRecoveryInProgress(:final sessionId):
        return ActiveBookingBanner(
          title: sessionId.isEmpty
              ? 'Sending ride request'
              : 'Checking your request',
          subtitle:
              activeSearch?.trip.destination.name ??
              'Reconnecting to your ride request…',
          tone: ActiveBookingBannerTone.active,
          isLoading: true,
          actionLabel: activeSearch != null ? 'View' : null,
          showActionArrow: activeSearch != null,
          onAction: activeSearch == null
              ? null
              : () => _openFindingDriverFromShell(activeSearch),
        );
      case BookingSessionRecoveryFailure(:final message):
        return ActiveBookingBanner(
          title: 'Request needs attention',
          subtitle: message,
          tone: ActiveBookingBannerTone.error,
          icon: LucideIcons.circle_alert,
          actionLabel: 'Retry',
          onAction: () => bookingBloc.add(const RestoreActiveBookingEvent()),
        );
      case BookingSearching(
        :final isDirect,
        :final targetDriver,
        :final sessionId,
      ):
        final destination = activeSearch?.trip.destination.name;
        final String title = sessionId == null
            ? 'Sending ride request'
            : isDirect
            ? 'Waiting for driver'
            : 'Searching for a driver';
        final String subtitle = _waitingSubtitle(
          driverName: targetDriver?.displayName,
          destinationName: destination,
          fallback: sessionId == null
              ? 'Confirming your trip request…'
              : 'Waiting for a driver to respond',
        );
        return ActiveBookingBanner(
          title: title,
          subtitle: subtitle,
          tone: ActiveBookingBannerTone.active,
          isLoading: true,
          actionLabel: activeSearch != null ? 'View' : null,
          showActionArrow: activeSearch != null,
          onAction: activeSearch == null
              ? null
              : () => _openFindingDriverFromShell(activeSearch),
        );
      case BookingOffersReceived(
        :final offers,
        :final isDirect,
        :final targetDriver,
      ):
        final destination = activeSearch?.trip.destination.name;
        final String title = offers.isNotEmpty
            ? '${offers.length} driver ${offers.length == 1 ? 'offer' : 'offers'}'
            : isDirect
            ? 'Waiting for driver'
            : 'Searching for a driver';
        final String subtitle = _waitingSubtitle(
          driverName: targetDriver?.displayName,
          destinationName: destination,
          fallback: offers.isNotEmpty
              ? 'Tap to review available offers'
              : 'Waiting for a driver to accept',
        );
        return ActiveBookingBanner(
          title: title,
          subtitle: subtitle,
          tone: ActiveBookingBannerTone.active,
          isLoading: offers.isEmpty,
          icon: LucideIcons.car,
          actionLabel: activeSearch != null ? 'View' : null,
          showActionArrow: activeSearch != null,
          onAction: activeSearch == null
              ? null
              : () => _openFindingDriverFromShell(activeSearch),
        );
      case BookingFindingNearbyDrivers(:final trip, :final drivers):
        if (drivers.isNotEmpty) {
          return ActiveBookingBanner(
            title: 'Nearby drivers ready',
            subtitle: '${drivers.first.displayName} • ${trip.destination.name}',
            tone: ActiveBookingBannerTone.active,
            icon: LucideIcons.car,
            actionLabel: activeSearch != null ? 'View' : null,
            showActionArrow: activeSearch != null,
            onAction: activeSearch == null
                ? null
                : () => _openFindingDriverFromShell(activeSearch),
            onDismiss: () => unawaited(
              _confirmCancelDriverSearch(bookingBloc, trip.destination.name),
            ),
          );
        }
        return ActiveBookingBanner(
          title: 'Looking for drivers',
          subtitle: 'To ${trip.destination.name}',
          tone: ActiveBookingBannerTone.active,
          isLoading: true,
          actionLabel: activeSearch != null ? 'View' : null,
          showActionArrow: activeSearch != null,
          onAction: activeSearch == null
              ? null
              : () => _openFindingDriverFromShell(activeSearch),
          onDismiss: () => unawaited(
            _confirmCancelDriverSearch(bookingBloc, trip.destination.name),
          ),
        );
      case FindingNearestDriver(:final trip):
        return ActiveBookingBanner(
          title: 'Looking for drivers',
          subtitle: 'To ${trip.destination.name}',
          tone: ActiveBookingBannerTone.active,
          isLoading: true,
          actionLabel: activeSearch != null ? 'View' : null,
          showActionArrow: activeSearch != null,
          onAction: activeSearch == null
              ? null
              : () => _openFindingDriverFromShell(activeSearch),
        );
      case NearestDriverFound(:final driver, :final trip):
        return ActiveBookingBanner(
          title: 'Nearby drivers ready',
          subtitle: '${driver.displayName} • ${trip.destination.name}',
          tone: ActiveBookingBannerTone.active,
          icon: LucideIcons.car,
          actionLabel: activeSearch != null ? 'View' : null,
          showActionArrow: activeSearch != null,
          onAction: activeSearch == null
              ? null
              : () => _openFindingDriverFromShell(activeSearch),
        );
      case BookingFailure():
        if (!state.isNoDriverOrTimedOutFailure ||
            identical(_dismissedBookingFailure, state)) {
          return null;
        }
        final retrySearch = bookingBloc.retryableDriverSearch;
        final destination = retrySearch?.trip.destination.name;
        final String title;
        final String subtitle;
        final IconData icon;
        final ActiveBookingBannerTone tone;
        if (state.isNoDriverFound) {
          title = 'No driver found';
          subtitle = destination == null
              ? 'No drivers available nearby. Try again.'
              : 'No drivers available for $destination.';
          icon = LucideIcons.search_x;
          tone = ActiveBookingBannerTone.error;
        } else if (state.isRequestExpired) {
          title = 'Driver timed out';
          subtitle = destination == null
              ? 'No driver accepted your request in time.'
              : 'No driver responded for $destination.';
          icon = LucideIcons.timer;
          tone = ActiveBookingBannerTone.warning;
        } else {
          title = 'Driver declined';
          subtitle = state.message;
          icon = LucideIcons.circle_alert;
          tone = ActiveBookingBannerTone.warning;
        }
        return ActiveBookingBanner(
          title: title,
          subtitle: subtitle,
          tone: tone,
          icon: icon,
          announceLiveRegion: true,
          actionLabel: retrySearch != null ? 'Retry' : null,
          onAction: retrySearch == null
              ? null
              : () => _openFindingDriverFromShell(
                  retrySearch,
                  bookingBloc: bookingBloc,
                  resetFirst: true,
                ),
          onDismiss: () => _dismissBookingNotice(bookingBloc, state),
        );
    }
  }

  String _waitingSubtitle({
    String? driverName,
    String? destinationName,
    required String fallback,
  }) {
    final driver = driverName?.trim() ?? '';
    final destination = destinationName?.trim() ?? '';
    if (driver.isNotEmpty && destination.isNotEmpty) {
      return '$driver • $destination';
    }
    if (destination.isNotEmpty) return 'To $destination';
    if (driver.isNotEmpty) return 'Waiting for $driver';
    return fallback;
  }

  Future<void> _confirmCancelDriverSearch(
    BookingBloc bookingBloc,
    String destinationName,
  ) async {
    if (!mounted || _isConfirmingBookingCancel) return;
    _isConfirmingBookingCancel = true;
    final confirmed = await showCancelBookingDialog(
      context,
      isActiveRequest: false,
      destinationName: destinationName,
    );
    _isConfirmingBookingCancel = false;
    if (!mounted || !confirmed) return;
    if (bookingBloc.state is BookingFindingNearbyDrivers) {
      bookingBloc.add(const CancelBookingEvent());
    }
  }

  void _openFindingDriverFromShell(
    ActiveDriverSearch search, {
    BookingBloc? bookingBloc,
    bool resetFirst = false,
  }) {
    if (!mounted) return;
    if (resetFirst) {
      bookingBloc?.add(const ResetBookingEvent());
    }
    final trip = search.trip;
    unawaited(
      context.pushNamed(
        BookingRoutes.findingDriver,
        extra: {
          'fare': trip.fare,
          'destination': trip.destination,
          'distance': trip.distance,
          'duration': trip.duration,
          if (search.distanceKm != null) 'distanceKm': search.distanceKm,
          if (search.durationMinutes != null)
            'durationMinutes': search.durationMinutes,
          'pickupAddress': trip.pickupAddress,
          'pickupLat': search.pickupLat,
          'pickupLng': search.pickupLng,
          'passengerNote': trip.passengerNote,
        },
      ),
    );
  }

  Future<void> _resumeMatchedRideFromShell(String? rideId) async {
    if (!mounted) return;
    final trimmed = rideId?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      unawaited(
        context.pushNamed(ActiveRideRoutes.trackDriver, extra: trimmed),
      );
      return;
    }
    await _resumeFromShell();
  }

  void _dismissBookingNotice(BookingBloc bookingBloc, BookingFailure failure) {
    setState(() => _dismissedBookingFailure = failure);
    bookingBloc.add(const ResetBookingEvent());
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

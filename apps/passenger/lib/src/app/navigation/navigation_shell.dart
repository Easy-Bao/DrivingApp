import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/app/navigation/floating_tab_bar.dart';
import 'package:passenger/src/app/navigation/guest_action_bar.dart';
import 'package:passenger/src/app/navigation/guest_help_bottom_sheet.dart';
import 'package:passenger/src/app/navigation/widgets/shell_tab_bar_section.dart';
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
    this.sessionService,
  });
  final StatefulNavigationShell navigationShell;
  final InboxCubit inboxCubit;
  final RealtimeWebSocketClient realtimeClient;
  final AppLifecycleCoordinator lifecycleCoordinator;
  final TabNavigationCoordinator navigationCoordinator;
  final BookingBloc? bookingBloc;
  final BookingDraftCubit? bookingDraftCubit;
  final TrackDriverCubit? trackDriverCubit;
  final SessionStore? sessionService;
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
        notification.dragDetails != null) {
      final scrollDelta = notification.scrollDelta;
      if (scrollDelta != null && scrollDelta != 0) {
        visible = scrollDelta < 0;
      }
    } else if (notification is UserScrollNotification) {
      visible = switch (notification.direction) {
        ScrollDirection.forward => true,
        ScrollDirection.reverse when notification.metrics.maxScrollExtent > 0 =>
          false,
        _ => null,
      };
    }
    if (visible case final nextVisible?
        when nextVisible != _activityTabBarVisible) {
      setState(() => _activityTabBarVisible = nextVisible);
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
          case GuestSession(:final wasExpired, :final wasSignedOut):
            _forceHomeForGuest();
            _loadedInboxPassengerId = null;
            _activePassengerId = null;
            unawaited(widget.realtimeClient.stop());
            if (!widget.inboxCubit.isClosed) {
              widget.inboxCubit.clearSessionData();
            }
            if (wasExpired) {
              AppSnackBar.show(
                context,
                'Session expired. Please sign in again.',
                tone: AppSnackBarTone.warning,
              );
            } else if (wasSignedOut) {
              AppSnackBar.show(
                context,
                'Signed out.',
                tone: AppSnackBarTone.info,
              );
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
                      bottomNavigationBar: _buildBottomBar(
                        context,
                        isAuthenticated: isAuthenticated,
                        isWide: isWide,
                        selectedIndex: selectedIndex,
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

  Widget _buildBottomBar(
    BuildContext context, {
    required bool isAuthenticated,
    required bool isWide,
    required int selectedIndex,
  }) {
    if (!isAuthenticated) {
      return GuestActionBar(
        onSignUp: () => context.pushNamed(AuthRoutes.signup),
        onSignIn: () => context.pushNamed(AuthRoutes.signin),
        onHelp: () => unawaited(_openGuestHelp(context)),
      );
    }
    if (isWide) return const SizedBox.shrink();

    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final visible =
        selectedIndex != 1 ||
        _activityTabBarVisible ||
        MediaQuery.accessibleNavigationOf(context);

    return ExcludeSemantics(
      excluding: !visible,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSlide(
          key: const ValueKey('passenger-tab-bar-visibility'),
          offset: visible ? Offset.zero : const Offset(0, 1),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : Duration(milliseconds: visible ? 120 : 180),
          curve: Curves.easeOutCubic,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPadding + 10),
            child: FractionallySizedBox(
              widthFactor: 0.86,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: ShellTabBarSection(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  inboxCubit: widget.inboxCubit,
                  pagePosition: widget.navigationCoordinator.pagePosition,
                  trackCubit: _resolveTrackDriverCubit(context),
                  bookingBloc: _resolveBookingBloc(context),
                  bookingDraftCubit: _resolveBookingDraftCubit(context),
                  dismissedBookingFailure: _dismissedBookingFailure,
                  onResumeRide: _resumeFromShell,
                  onResumeMatchedRide: _resumeMatchedRideFromShell,
                  onOpenFindingDriver: _openFindingDriverFromShell,
                  onConfirmCancelDriverSearch: _confirmCancelDriverSearch,
                  onDismissBookingNotice: _dismissBookingNotice,
                  onContinuePendingBooking: _continuePendingBookingFromShell,
                ),
              ),
            ),
          ),
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
      return null;
    }
  }

  BookingBloc? _resolveBookingBloc(BuildContext context) {
    if (widget.bookingBloc != null) return widget.bookingBloc;
    try {
      return BlocProvider.of<BookingBloc>(context);
    } catch (_) {
      return null;
    }
  }

  BookingDraftCubit? _resolveBookingDraftCubit(BuildContext context) {
    if (widget.bookingDraftCubit != null) return widget.bookingDraftCubit;
    try {
      return BlocProvider.of<BookingDraftCubit>(context);
    } catch (_) {
      return null;
    }
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
    final state = bookingBloc.state;
    if (state is BookingFindingNearbyDrivers ||
        state is FindingNearestDriver ||
        state is NearestDriverFound) {
      bookingBloc.add(const CancelBookingEvent());
      AppSnackBar.show(
        context,
        'Driver search canceled.',
        tone: AppSnackBarTone.info,
      );
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

  Future<void> _resumeFromShell() async {
    if (!mounted) return;
    final session = widget.sessionService;
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

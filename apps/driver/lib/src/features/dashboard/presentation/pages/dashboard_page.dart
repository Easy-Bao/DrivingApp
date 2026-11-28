import 'dart:async';
import 'dart:developer' as dev;

import 'package:design_system/design_system.dart';
import 'package:driver/src/core/formatters/value_formatters.dart';
import 'package:driver/src/features/active_ride/active_ride.dart';
import 'package:driver/src/features/active_ride/active_ride_routes.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver/src/features/dashboard/dashboard_routes.dart';
import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:driver/src/features/dashboard/presentation/controllers/dashboard_realtime_parser.dart';
import 'package:driver/src/features/dashboard/presentation/controllers/incoming_request_alert.dart';
import 'package:driver/src/features/dashboard/presentation/pages/incoming_ride_request_page.dart';
import 'package:driver/src/features/dashboard/presentation/widgets/active_bookings_list.dart';
import 'package:driver/src/features/dashboard/presentation/widgets/availability_card.dart';
import 'package:driver/src/features/dashboard/presentation/widgets/dashboard_stats_row.dart';
import 'package:driver/src/features/dashboard/presentation/widgets/dashboard_status_indicator.dart';
import 'package:driver/src/features/dashboard/presentation/widgets/trip_ended_dialog.dart';
import 'package:driver/src/features/dashboard/presentation/widgets/trip_recovery_review_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart';

bool shouldAnimateStatusPulse({
  required bool isOnline,
  required bool isForeground,
}) => isOnline && isForeground;

class const DashboardPage({
  super.key,
  required this.lifecycleCoordinator,
  required this.realtimeClient,
}) extends StatefulWidget {
  final AppLifecycleCoordinator lifecycleCoordinator;
  final RealtimeWebSocketClient realtimeClient;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  late final AnimationController _pulseAnimationController;
  Timer? _rideTriggerTimer;
  Timer? _presenceHeartbeatTimer;
  Timer? _locationAccessPoller;
  Timer? _requestCountdownTimer;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<RealtimeEvent>? _realtimeEventsSubscription;
  late final StreamSubscription<AppLifecycleStatus> _lifecycleSubscription;
  late final RealtimeWebSocketClient _realtimeClient;
  bool _isTogglingOnline = false;
  bool _isResumingOnline = false;
  bool _isRefreshingPresence = false;
  bool? _pendingOnline;
  bool _isShowingRequest = false;
  bool _isOpeningTrip = false;
  bool _isActiveTripRouteOpen = false;
  bool _tripNavigationScheduled = false;
  String? _attemptedTripId;
  String? _tripNavigationError;
  final _reviewedTripIds = <String>{};
  int _pollGeneration = 0;
  int _locationAccessFailures = 0;
  bool _isCheckingLocationAccess = false;
  bool _isForcingOfflineForLocationLoss = false;
  bool _isForeground = true;
  bool _isHandlingRideTerminal = false;

  static const _locationAccessPollInterval = Duration(seconds: 5);
  static const _locationAccessFailureThreshold = 2;

  @override
  void initState() {
    super.initState();
    _isForeground = widget.lifecycleCoordinator.isForeground;
    _lifecycleSubscription = widget.lifecycleCoordinator.changes.listen(
      _onLifecycleChanged,
    );
    _realtimeClient = widget.realtimeClient;
    _realtimeClient.setActiveTripResyncHandler(_resyncActiveTrip);
    _realtimeEventsSubscription = _realtimeClient.events.listen(
      _handleRealtimeEvent,
    );
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final dashboardState = BlocProvider.of<DashboardCubit>(context).state;
        _scheduleActiveTripNavigation();
        unawaited(_showIncomingRequest());
        _syncPulseAnimation(dashboardState.isOnline);
        _syncRequestCountdownTimer(dashboardState);
        _startLocationAccessMonitoring();
        unawaited(_loadActiveTrips());
        if (dashboardState.isOnline && _isForeground) {
          unawaited(_resumeOnlineTelemetry());
        }
      }
    });
  }

  @override
  void dispose() {
    _pollGeneration++;
    _realtimeClient.setActiveTripResyncHandler(null);
    unawaited(_lifecycleSubscription.cancel());
    _pulseAnimationController.dispose();
    _rideTriggerTimer?.cancel();
    _presenceHeartbeatTimer?.cancel();
    _locationAccessPoller?.cancel();
    _requestCountdownTimer?.cancel();
    unawaited(_locationSubscription?.cancel());
    _locationSubscription = null;
    unawaited(_realtimeEventsSubscription?.cancel());
    _realtimeEventsSubscription = null;
    super.dispose();
  }

  Future<void> _resyncActiveTrip() async {
    if (!mounted || !_isForeground) return;
    await Future.wait<void>([
      BlocProvider.of<DashboardCubit>(context).resyncActiveTrip(),
      BlocProvider.of<RideFlowCubit>(context).syncAuthoritativeRideState(),
    ]);
  }

  void _syncPulseAnimation(bool isOnline) {
    final shouldPulse = shouldAnimateStatusPulse(
      isOnline: isOnline,
      isForeground: _isForeground,
    );
    if (shouldPulse) {
      if (!_pulseAnimationController.isAnimating) {
        _pulseAnimationController.repeat(reverse: true);
      }
      return;
    }
    _pulseAnimationController.stop();
  }

  void _onLifecycleChanged(AppLifecycleStatus status) {
    final isForeground = status == AppLifecycleStatus.foreground;
    if (!isForeground) {
      if (_isForeground) {
        _isForeground = false;
        _pulseAnimationController.stop();
        _suspendForegroundWork();
      }
      return;
    }

    if (_isForeground || !mounted) return;
    _isForeground = true;
    final dashboardState = BlocProvider.of<DashboardCubit>(context).state;
    _syncPulseAnimation(dashboardState.isOnline);
    _syncRequestCountdownTimer(dashboardState);
    _scheduleActiveTripNavigation();
    unawaited(_showIncomingRequest());
    unawaited(_resumeForegroundWork());
  }

  Future<void> _resumeForegroundWork() async {
    final wasExpired = await BlocProvider.of<DashboardCubit>(context)
        .checkOnlineInactivity();
    if (wasExpired) {
      if (mounted) {
        AppSnackBar.show(
          context,
          'You were switched offline due to inactivity.',
          tone: AppSnackBarTone.warning,
        );
      }
      return;
    }
    if (!mounted || !_isForeground) return;
    await _loadActiveTrips();
    if (!mounted || !_isForeground) return;
    await BlocProvider.of<RideFlowCubit>(context).syncAuthoritativeRideState();
    if (!mounted || !_isForeground) return;
    await _refreshLocationAfterResume();
  }

  Future<void> _loadActiveTrips() async {
    if (!mounted || !_isForeground) return;
    await BlocProvider.of<DashboardCubit>(context)
        .loadDispatchSnapshot(includeOffers: false, silent: true);
  }

  Future<void> _refreshLocationAfterResume() async {
    if (!mounted) return;
    final LocationAccessState accessState;
    try {
      accessState = await LocationService.getAccessState();
    } catch (error, stackTrace) {
      dev.log(
        'Unable to verify driver location access after resume.',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }
    if (!mounted) return;
    final dashboardState = BlocProvider.of<DashboardCubit>(context).state;
    if (accessState != LocationAccessState.ready) {
      if (dashboardState.isOnline) {
        await _forceOfflineForLocationLoss();
      }
      return;
    }

    if (dashboardState.isOnline) {
      await _resumeOnlineTelemetry();
    }
  }

  void _startLocationAccessMonitoring() {
    if (!_isForeground) return;
    _locationAccessPoller ??= Timer.periodic(
      _locationAccessPollInterval,
      (_) => unawaited(_checkLocationAccess()),
    );
    unawaited(_checkLocationAccess());
  }

  Future<void> _checkLocationAccess() async {
    if (!mounted ||
        !_isForeground ||
        _isCheckingLocationAccess ||
        _isForcingOfflineForLocationLoss) {
      return;
    }

    final cubit = BlocProvider.of<DashboardCubit>(context);
    if (!cubit.state.isOnline && _locationAccessPoller != null) {
      _stopLocationAccessMonitoring();
      return;
    }

    _isCheckingLocationAccess = true;
    try {
      final accessState = await LocationService.getAccessState();
      if (!mounted) return;

      if (accessState == LocationAccessState.ready) {
        _locationAccessFailures = 0;
        if (!cubit.state.isOnline) _stopLocationAccessMonitoring();
        return;
      }

      _locationAccessFailures++;
      if (!cubit.state.isOnline ||
          _locationAccessFailures < _locationAccessFailureThreshold) {
        return;
      }

      _stopLocationAccessMonitoring();
      await _forceOfflineForLocationLoss();
    } catch (error, stackTrace) {
      // A plugin/OS read failure is not proof that the driver revoked access.
      // Keep the driver's intent and let the next bounded check reconcile it.
      dev.log(
        'Unable to verify driver location access.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _isCheckingLocationAccess = false;
    }
  }

  void _stopLocationAccessMonitoring() {
    _locationAccessPoller?.cancel();
    _locationAccessPoller = null;
    _locationAccessFailures = 0;
  }

  Future<void> _forceOfflineForLocationLoss() async {
    if (!mounted || _isForcingOfflineForLocationLoss) return;
    final cubit = BlocProvider.of<DashboardCubit>(context);
    if (!cubit.state.isOnline) return;

    _isForcingOfflineForLocationLoss = true;
    try {
      final position = LocationService.lastPosition;
      await cubit.forceOffline(
        lat: position?.latitude ?? 0,
        lng: position?.longitude ?? 0,
      );
      if (mounted) {
        AppSnackBar.show(
          context,
          'You were switched offline because location access is unavailable.',
          tone: AppSnackBarTone.warning,
        );
        await BlocProvider.of<LocationAccessCubit>(context).refresh();
      }
    } finally {
      _isForcingOfflineForLocationLoss = false;
    }
  }

  Future<void> _resumeOnlineTelemetry() async {
    if (!_isForeground || _isResumingOnline) return;
    _isResumingOnline = true;
    try {
      final position =
          await LocationService.getCurrentPosition() ??
          LocationService.lastPosition;
      if (!mounted) return;
      final cubit = BlocProvider.of<DashboardCubit>(context);
      if (!cubit.state.isOnline) return;

      await cubit.refreshOnlinePresence(
        lat: position?.latitude ?? 0,
        lng: position?.longitude ?? 0,
      );
      if (!mounted || !cubit.state.isOnline) return;
      // Keep the heartbeat alive after a transient refresh failure; the next
      // tick can reconcile the server without changing the driver's intent.
      _startPolling();
    } catch (error) {
      dev.log(
        'Unable to restore online driver telemetry; preserving online intent.',
        error: error,
      );
      if (mounted && BlocProvider.of<DashboardCubit>(context).state.isOnline) {
        _startPolling();
      }
    } finally {
      _isResumingOnline = false;
    }
  }

  void _refreshRequestCountdowns() {
    if (!mounted || !_isForeground) return;
    final cubit = BlocProvider.of<DashboardCubit>(context);
    cubit.removeExpiredRideOffers();
    _syncRequestCountdownTimer(cubit.state);
  }

  void _syncRequestCountdownTimer(DashboardState state) {
    final hasActiveOffers =
        state.activeBids.isNotEmpty || state.submittedOffers.isNotEmpty;
    if (!_isForeground || !state.isOnline || !hasActiveOffers) {
      _requestCountdownTimer?.cancel();
      _requestCountdownTimer = null;
      return;
    }
    _requestCountdownTimer ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshRequestCountdowns(),
    );
  }

  void _startPolling() {
    if (!_isForeground) return;
    final pollGeneration = ++_pollGeneration;
    _startLocationAccessMonitoring();
    _cancelLocationSubscription();
    _locationSubscription = LocationService.getPositionStream().listen(
      (position) {
        if (!mounted || pollGeneration != _pollGeneration) return;
        unawaited(
          BlocProvider.of<DashboardCubit>(context).publishDriverLocation(
            lat: position.latitude,
            lng: position.longitude,
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        dev.log(
          'Driver location stream failed.',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => unawaited(_refreshOnlinePresence()),
    );
    unawaited(_startRealtimeUpdates());

    _rideTriggerTimer?.cancel();
    _rideTriggerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted ||
          pollGeneration != _pollGeneration ||
          !BlocProvider.of<DashboardCubit>(context).state.isOnline) {
        timer.cancel();
        return;
      }
      unawaited(_pollRideData(pollGeneration));
    });
    unawaited(_pollRideData(pollGeneration));
  }

  Future<void> _startRealtimeUpdates() async {
    if (!_isForeground) return;
    try {
      await _realtimeClient.start();
    } catch (error) {
      dev.log('Unable to start driver ride realtime updates: $error');
    }
  }

  void _handleRealtimeEvent(RealtimeEvent event) {
    if (!mounted || !_isForeground) return;

    if (event is RideStatusChangedEvent) {
      _handleRideStatusChanged(event);
      return;
    }

    if (!BlocProvider.of<DashboardCubit>(context).state.isOnline) return;

    // Direct requests already carry the target driver's topic. Refresh the
    // authoritative offers immediately instead of waiting for the fallback
    // polling interval.
    if (event is RideOfferCreatedEvent) {
      unawaited(IncomingRequestAlert.play());
      unawaited(_pollRideData(_pollGeneration));
      return;
    }
    if (event is RideOfferUpdatedEvent) {
      final resolvedSessionId = resolvedOfferSessionIdFromUpdate(event);
      if (resolvedSessionId != null) {
        BlocProvider.of<DashboardCubit>(context)
            .resolveSubmittedOffer(resolvedSessionId);
      }

      unawaited(_pollRideData(_pollGeneration));
      return;
    }
    if (event is! RideMatchedEvent) return;

    final matched = parseMatchedRideEvent(event);
    if (matched == null) {
      if (event.envelope.payload['ride'] is! Map) {
        unawaited(_pollRideData(_pollGeneration));
      }
      return;
    }

    BlocProvider.of<DashboardCubit>(context)
        .mergeActiveRide(matched.snapshot, sessionId: matched.sessionId);
  }

  void _handleRideStatusChanged(RideStatusChangedEvent event) {
    final parsed = parseRideStatusChangedEvent(event);
    if (parsed == null) return;
    final terminalStatus = parsed.status;
    if (!terminalStatus.isTerminal) {
      unawaited(BlocProvider.of<DashboardCubit>(context).resyncActiveTrip());
      return;
    }

    final rideId = parsed.rideId;
    if (rideId == null) return;

    final dashboardCubit = BlocProvider.of<DashboardCubit>(context);
    final rideFlowCubit = BlocProvider.of<RideFlowCubit>(context);
    final flowRideId = rideFlowCubit.activeRideId;
    final dashboardRideId = dashboardCubit.state.activeRide?.id;

    // Tombstone synchronously so an in-flight snapshot cannot win while the
    // active-ride session cleanup is awaiting storage I/O.
    dashboardCubit.removeActiveRide(rideId);

    final isCurrentRide = flowRideId != null
        ? flowRideId == rideId
        : dashboardRideId == rideId;
    if (!isCurrentRide) return;

    unawaited(
      rideFlowCubit.handleExternalTerminalRide(
        rideId: rideId,
        status: terminalStatus.value,
      ),
    );
  }

  void _handleRideFlowTerminal(RideFlowTerminal terminal) {
    BlocProvider.of<DashboardCubit>(context).removeActiveRide(terminal.rideId);
    if (_isHandlingRideTerminal) return;
    if (terminal.status == 'completed') {
      return;
    }
    _isHandlingRideTerminal = true;
    unawaited(_showRideTerminalDialog(terminal));
  }

  Future<void> _showRideTerminalDialog(RideFlowTerminal terminal) async {
    try {
      if (!mounted) return;
      final (title, message) = switch (terminal.status) {
        'not_found' => (
          'Trip unavailable',
          'This trip is no longer available. You have been returned to the dispatch queue.',
        ),
        _ => (
          'Trip canceled',
          'This trip was canceled. Return to dispatch to view your other bookings and ride requests.',
        ),
      };
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) =>
            TripEndedDialog(title: title, message: message),
      );
      if (mounted) {
        if (_isActiveTripRouteOpen) {
          context.goNamed(DashboardRoutes.dashboard);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_showIncomingRequest());
        });
      }
    } finally {
      _isHandlingRideTerminal = false;
    }
  }

  Future<void> _pollRideData(int pollGeneration) async {
    if (!mounted ||
        !_isForeground ||
        pollGeneration != _pollGeneration ||
        !BlocProvider.of<DashboardCubit>(context).state.isOnline) {
      return;
    }

    await BlocProvider.of<DashboardCubit>(context)
        .loadDispatchSnapshot(silent: true);
    if (mounted && pollGeneration != _pollGeneration) {
      unawaited(_pollRideData(_pollGeneration));
    }
  }

  Future<void> _refreshOnlinePresence() async {
    if (!mounted || !_isForeground || _isRefreshingPresence) return;
    final cubit = BlocProvider.of<DashboardCubit>(context);
    if (!cubit.state.isOnline) return;

    _isRefreshingPresence = true;
    try {
      final position =
          LocationService.lastPosition ??
          await LocationService.getCurrentPosition();
      if (!mounted || !cubit.state.isOnline) return;
      await cubit.refreshOnlinePresence(
        lat: position?.latitude ?? 0,
        lng: position?.longitude ?? 0,
      );
    } finally {
      _isRefreshingPresence = false;
    }
  }

  void _suspendForegroundWork() {
    unawaited(BlocProvider.of<DashboardCubit>(context).recordActivity());
    _cancelOnlineForegroundWork(clearActiveBids: false);
    _requestCountdownTimer?.cancel();
    _requestCountdownTimer = null;
  }

  void _stopPolling() {
    _cancelOnlineForegroundWork(clearActiveBids: true);
  }

  void _cancelOnlineForegroundWork({required bool clearActiveBids}) {
    _pollGeneration++;
    _cancelLocationSubscription();
    _rideTriggerTimer?.cancel();
    _rideTriggerTimer = null;
    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = null;
    _stopLocationAccessMonitoring();
    unawaited(_realtimeClient.stop());
    if (mounted && clearActiveBids) {
      BlocProvider.of<DashboardCubit>(context).clearActiveBids();
    }
  }

  void _cancelLocationSubscription() {
    final subscription = _locationSubscription;
    _locationSubscription = null;
    if (subscription != null) unawaited(subscription.cancel());
  }

  Future<void> _toggleOnline(BuildContext context, bool requestedOnline) async {
    if (_isTogglingOnline) return;
    setState(() {
      _isTogglingOnline = true;
      _pendingOnline = requestedOnline;
    });

    try {
      if (requestedOnline && await _hasReadyLocationAccess(context) == false) {
        if (context.mounted) {
          unawaited(BlocProvider.of<LocationAccessCubit>(context).enable());
        }
        return;
      }

      final position = LocationService.lastPosition;

      if (!context.mounted) return;

      final dashboardCubit = BlocProvider.of<DashboardCubit>(context);

      await dashboardCubit.toggleOnline(
        requestedOnline: requestedOnline,
        lat: position?.latitude ?? 0,
        lng: position?.longitude ?? 0,
      );
      if (mounted && context.mounted) {
        final err = dashboardCubit.state.errorMessage;
        if (err != null && err.isNotEmpty) {
          dashboardCubit.dismissError();
          AppSnackBar.show(context, err, tone: AppSnackBarTone.error);
        }
      }
    } finally {
      if (mounted && context.mounted) {
        final resolvedOnline = BlocProvider.of<DashboardCubit>(context)
            .state
            .isOnline;
        _pendingOnline = null;
        if (resolvedOnline) {
          _startPolling();
          if (LocationService.lastPosition == null) {
            unawaited(_publishInitialPositionAfterToggle());
          }
        }
        setState(() => _isTogglingOnline = false);
      }
    }
  }

  Future<void> _publishInitialPositionAfterToggle() async {
    final position = await LocationService.getCurrentPosition();
    if (!mounted || position == null) return;
    final cubit = BlocProvider.of<DashboardCubit>(context);
    if (!cubit.state.isOnline) return;
    await cubit.publishDriverLocation(
      lat: position.latitude,
      lng: position.longitude,
    );
  }

  Future<bool> _hasReadyLocationAccess(BuildContext context) async {
    try {
      return await LocationService.getAccessState() ==
          LocationAccessState.ready;
    } catch (error, stackTrace) {
      dev.log(
        'Unable to verify location access before changing availability.',
        error: error,
        stackTrace: stackTrace,
      );

      return false;
    }
  }

  bool get _canPresentIncomingRequest {
    if (!mounted || _isShowingRequest || _isOpeningTrip || !_isForeground) {
      return false;
    }
    if (ModalRoute.of(context)?.isCurrent != true) {
      return false;
    }
    final rootCanPop = Navigator.of(context, rootNavigator: true).canPop();
    return !rootCanPop || _isActiveTripRouteOpen;
  }

  Future<void> _showIncomingRequest() async {
    if (!_canPresentIncomingRequest) {
      return;
    }
    final cubit = BlocProvider.of<DashboardCubit>(context);
    final state = cubit.state;
    if (!state.isOnline ||
        state.isAtBookingCapacity ||
        (state.activeBids.isEmpty && state.submittedOffers.isEmpty)) {
      return;
    }
    final sessionId = valueAsString(
      (state.submittedOffers.isNotEmpty
          ? state.submittedOffers.first
          : state.activeBids.first)['id'],
    );
    if (sessionId == null) return;
    final previousRideIds = state.activeRides.map((ride) => ride.id).toSet();
    _isShowingRequest = true;
    var acceptedRequest = false;
    try {
      final result = await Navigator.of(context, rootNavigator: true)
          .push<bool>(
            PageRouteBuilder<bool>(
              fullscreenDialog: true,
              pageBuilder: (_, animation, secondaryAnimation) =>
                  IncomingRideRequestPage(cubit: cubit, sessionId: sessionId),
              transitionsBuilder: (_, animation, secondaryAnimation, child) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                );
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                );
              },
              transitionDuration: AppTransitions.modalDuration,
              reverseTransitionDuration: AppTransitions.modalDuration,
            ),
          );
      acceptedRequest = result ?? false;
    } finally {
      _isShowingRequest = false;
    }
    if (mounted) {
      final assigned = cubit.state.activeRides
          .where((ride) => !previousRideIds.contains(ride.id))
          .firstOrNull;
      if (assigned != null && !_isActiveTripRouteOpen) {
        _scheduleActiveTripNavigation(rideId: assigned.id);
      } else {
        if (assigned != null && _isActiveTripRouteOpen) {
          AppSnackBar.show(
            context,
            'Ride added to your active bookings.',
            tone: AppSnackBarTone.success,
          );
        } else if (acceptedRequest) {
          AppSnackBar.show(
            context,
            'This ride request is no longer available.',
            tone: AppSnackBarTone.warning,
          );
        }
        unawaited(_refreshOnlinePresence());
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_showIncomingRequest());
      });
    }
  }

  void _scheduleActiveTripNavigation({String? rideId}) {
    if (_tripNavigationScheduled || !mounted) return;
    _tripNavigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tripNavigationScheduled = false;
      if (mounted) unawaited(_openActiveTrip(rideId: rideId));
    });
  }

  Future<void> _openActiveTrip({String? rideId, bool retry = false}) async {
    if (!mounted ||
        !_isForeground ||
        _isOpeningTrip ||
        _isActiveTripRouteOpen ||
        _isShowingRequest ||
        ModalRoute.of(context)?.isCurrent != true ||
        Navigator.of(context, rootNavigator: true).canPop()) {
      return;
    }
    final rides = BlocProvider.of<DashboardCubit>(context).state.activeRides;
    final trip = rideId == null
        ? rides.firstOrNull
        : rides.where((ride) => ride.id == rideId).firstOrNull;
    if (trip == null ||
        (_attemptedTripId == trip.id &&
            _tripNavigationError != null &&
            !retry)) {
      return;
    }
    setState(() {
      _isOpeningTrip = true;
      _attemptedTripId = trip.id;
      _tripNavigationError = null;
    });
    Map<String, Object?>? routeExtra;
    var resolvedWithoutRoute = false;
    try {
      (routeExtra, resolvedWithoutRoute) = await _prepareTripNavigation(trip);
    } catch (_) {
      routeExtra = null;
      resolvedWithoutRoute = false;
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningTrip = false;
          if (routeExtra == null && !resolvedWithoutRoute) {
            _tripNavigationError = 'Your trip could not be opened. Refresh its status and try again.';
          }
        });
      }
    }
    if (!mounted || !context.mounted) return;
    if (routeExtra == null) {
      unawaited(_showIncomingRequest());
      return;
    }
    _isActiveTripRouteOpen = true;
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_showIncomingRequest());
      });
      await context.pushNamed(ActiveRideRoutes.trip, extra: routeExtra);
    } finally {
      _isActiveTripRouteOpen = false;
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_showIncomingRequest());
        });
      }
    }
  }

  Future<(Map<String, Object?>?, bool)> _prepareTripNavigation(
    RideSnapshot trip,
  ) async {
    final rideId = trip.id;
    final rideFlowCubit = BlocProvider.of<RideFlowCubit>(context);
    var resolvedTrip = await BlocProvider.of<DashboardCubit>(context)
        .fetchAuthoritativeRide(trip.id);
    if (resolvedTrip == null) return (null, false);
    if (!mounted || !context.mounted) return (null, false);
    if (await _discardTerminalTrip(resolvedTrip, rideId)) return (null, true);
    if (!mounted || !context.mounted) return (null, false);
    if (!_reviewedTripIds.contains(rideId) &&
        resolvedTrip.needsRecoveryReview(DateTime.now())) {
      final isInTransit = resolvedTrip.status == 'in_transit';
      final shouldOpen = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => TripRecoveryReviewDialog(isInTransit: isInTransit),
      );
      if (!mounted || !context.mounted) return (null, false);
      if (shouldOpen != true) return (null, true);
      _reviewedTripIds.add(rideId);
      // The passenger may cancel while the review is open.
      resolvedTrip = await BlocProvider.of<DashboardCubit>(context)
          .fetchAuthoritativeRide(rideId);
      if (!mounted || !context.mounted || resolvedTrip == null) {
        return (null, false);
      }
      if (await _discardTerminalTrip(resolvedTrip, rideId)) return (null, true);
      if (!mounted || !context.mounted) return (null, false);
    }
    final fare = resolvedTrip.farePesos;
    final distance = resolvedTrip.distanceKm;
    final duration = resolvedTrip.durationMinutes;
    if (fare == null || distance == null || duration == null) {
      return (null, false);
    }

    final resumed = await rideFlowCubit.resumeRide(
      rideId: rideId,
      bookingReference: resolvedTrip.bookingReference,
      status: resolvedTrip.status.isEmpty ? 'accepted' : resolvedTrip.status,
      passengerName: resolvedTrip.passengerName ?? 'Passenger',
      passengerId: resolvedTrip.passengerId,
      distanceKm: resolvedTrip.distanceKm,
      pickupLatitude: resolvedTrip.pickupLatitude,
      pickupLongitude: resolvedTrip.pickupLongitude,
      destinationLatitude: resolvedTrip.dropoffLatitude,
      destinationLongitude: resolvedTrip.dropoffLongitude,
      arrivedAt: resolvedTrip.arrivedAt,
      waitingUntil: resolvedTrip.waitingUntil,
    );
    if (!resumed || !mounted || !context.mounted) return (null, false);

    return (
      <String, Object?>{
        'rideId': rideId,
        'pickup': resolvedTrip.pickupName,
        'dropoff': resolvedTrip.dropoffName,
        'distance': distance,
        'fare': fare,
        'duration': '${duration.toStringAsFixed(0)} min',
      },
      true,
    );
  }

  Future<bool> _discardTerminalTrip(RideSnapshot trip, String rideId) async {
    if (!trip.isTerminal) return false;

    BlocProvider.of<DashboardCubit>(context).removeActiveRide(rideId);
    final rideFlowCubit = BlocProvider.of<RideFlowCubit>(context);
    if (rideFlowCubit.activeRideId == rideId) {
      await rideFlowCubit.reset();
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DashboardCubit, DashboardState>(
          listenWhen: (previous, current) => current.activeRides.any(
            (ride) => !previous.activeRides.any((old) => old.id == ride.id),
          ),
          listener: (_, state) =>
              _scheduleActiveTripNavigation(rideId: state.activeRides.last.id),
        ),
        BlocListener<DashboardCubit, DashboardState>(
          listenWhen: (previous, current) =>
              previous.activeBids != current.activeBids ||
              previous.submittedOffers != current.submittedOffers ||
              previous.isOnline != current.isOnline ||
              (previous.activeRides != current.activeRides &&
                  current.activeRides.isEmpty),
          listener: (_, state) {
            _syncRequestCountdownTimer(state);
            unawaited(_showIncomingRequest());
          },
        ),
        BlocListener<RideFlowCubit, RideFlowState>(
          listenWhen: (_, current) => current is RideFlowTerminal,
          listener: (context, state) {
            if (state case final RideFlowTerminal terminal) {
              _handleRideFlowTerminal(terminal);
            }
          },
        ),
        BlocListener<DashboardCubit, DashboardState>(
          listenWhen: (previous, current) =>
              previous.isOnline != current.isOnline,
          listener: (context, state) {
            _syncPulseAnimation(state.isOnline);
            if (state.isOnline) {
              // A user-triggered transition already establishes telemetry and
              // starts the background service in the repository. Re-running
              // the full online handshake here creates a duplicate request
              // and can race the first transition. Restored sessions still
              // need the reconciliation performed by
              // _resumeOnlineTelemetry().
              if (!_isTogglingOnline) {
                unawaited(_resumeOnlineTelemetry());
              }
            } else {
              _stopPolling();
            }
          },
        ),
        BlocListener<LocationAccessCubit, LocationAccessViewState>(
          listenWhen: (_, current) => current is LocationAccessUnavailable,
          listener: (context, _) {
            if (BlocProvider.of<DashboardCubit>(context).state.isOnline) {
              unawaited(_forceOfflineForLocationLoss());
            }
          },
        ),
      ],
      child: BlocBuilder<DashboardCubit, DashboardState>(
        buildWhen: (previous, current) =>
            previous.isOnline != current.isOnline ||
            previous.isLoadingStats != current.isLoadingStats ||
            previous.hasLoadedStats != current.hasLoadedStats ||
            previous.earnings != current.earnings ||
            previous.completedTrips != current.completedTrips ||
            previous.errorMessage != current.errorMessage ||
            previous.statsErrorMessage != current.statsErrorMessage ||
            previous.activeRides != current.activeRides,
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: false,
                  child: Scaffold(
                    appBar: const DashboardAppBar(),
                    body: SafeArea(
                      top: false,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppLayout.contentMaxWidth,
                          ),
                          child: RefreshIndicator(
                            color: context.colorScheme.onSurface,
                            onRefresh: () async {
                              await Future.wait([
                                BlocProvider.of<DashboardCubit>(context)
                                    .loadStats(),
                                _loadActiveTrips(),
                              ]);
                            },
                            child: CustomScrollView(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: ClampingScrollPhysics(),
                              ),
                              slivers: [
                                SliverList.list(
                                  children: [
                                    const SizedBox(height: AppSpacing.sm),
                                    _buildOnlineCardBanner(context, state),
                                    if (state.errorMessage
                                        case final errorMessage?) ...[
                                      const SizedBox(height: AppSpacing.md),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppLayout.pagePadding,
                                        ),
                                        child: AppErrorBanner(
                                          message: errorMessage,
                                          onRetry: () => unawaited(
                                            BlocProvider.of<DashboardCubit>(
                                              context,
                                            ).loadDispatchSnapshot(force: true),
                                          ),
                                          onDismiss: () =>
                                              BlocProvider.of<DashboardCubit>(
                                                context,
                                              ).dismissError(),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: AppSpacing.md),
                                    _buildStatsRow(context, state),
                                    const SizedBox(height: AppSpacing.xxl),
                                  ],
                                ),
                                if (state.activeRides.isNotEmpty)
                                  SliverToBoxAdapter(
                                    child: ActiveBookingsList(
                                      rides: state.activeRides,
                                      openingRideId: _isOpeningTrip
                                          ? _attemptedTripId
                                          : null,
                                      errorMessage: _tripNavigationError,
                                      onRetry: () => unawaited(
                                        _openActiveTrip(
                                          rideId: _attemptedTripId,
                                          retry: true,
                                        ),
                                      ),
                                      onOpen: (id) => unawaited(
                                        _openActiveTrip(
                                          rideId: id,
                                          retry: true,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.xxl,
                                      ),
                                      child: Center(
                                        child: DashboardStatusIndicator(
                                          isOnline: state.isOnline,
                                          statusPulse:
                                              _pulseAnimationController,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOnlineCardBanner(BuildContext context, DashboardState state) {
    final isOnline = _pendingOnline ?? state.isOnline;
    final locationReady = context.select<LocationAccessCubit, bool>(
      (cubit) => cubit.state is LocationAccessReady,
    );
    return AvailabilityCard(
      isOnline: isOnline,
      isToggling: _isTogglingOnline,
      hasActiveRide: state.activeRide != null,
      statusPulse: _pulseAnimationController,
      onChanged: (locationReady || isOnline)
          ? (value) => unawaited(_toggleOnline(context, value))
          : null,
    );
  }

  Widget _buildStatsRow(BuildContext context, DashboardState state) {
    return DashboardStatsRow(
      isLoadingStats: state.isLoadingStats,
      hasExistingStats: state.hasLoadedStats,
      earnings: state.earnings,
      completedTrips: state.completedTrips,
      hasError: state.statsErrorMessage != null,
      errorMessage: state.statsErrorMessage,
      onRetry: () =>
          unawaited(BlocProvider.of<DashboardCubit>(context).loadStats()),
    );
  }
}

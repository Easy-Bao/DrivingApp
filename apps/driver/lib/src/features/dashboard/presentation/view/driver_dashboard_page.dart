import 'package:driver/src/features/active_ride/active_ride.dart';

import 'dart:async';
import 'dart:developer' as dev;

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/active_ride_routes.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver/src/features/dashboard/dashboard_routes.dart';
import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:driver/src/features/dashboard/presentation/widgets/driver_availability_card.dart';
import 'package:driver/src/features/dashboard/presentation/widgets/driver_dashboard_stats_row.dart';
import 'package:driver/src/features/dashboard/presentation/view/incoming_ride_request_page.dart';
import 'package:driver/src/features/location/presentation/bloc/location_access/driver_location_access_cubit.dart';
import 'package:driver/src/features/location/presentation/bloc/location_access/driver_location_access_state.dart';
import 'package:driver/src/infrastructure/notifications/driver_incoming_request_alert.dart';
import 'package:driver/src/presentation/formatters/driver_value_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';

bool _isActiveTripStatus(Object? value) {
  return const {
    'assigned',
    'accepted',
    'arrived',
    'in_transit',
  }.contains(valueAsString(value));
}

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
  bool _isRestoringPendingCashSettlement = false;

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
    _startRequestCountdownTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final dashboardState = BlocProvider.of<DashboardCubit>(context).state;
        _scheduleActiveTripNavigation();
        unawaited(_showIncomingRequest());
        _syncPulseAnimation(dashboardState.isOnline);
        _startLocationAccessMonitoring();
        unawaited(_loadActiveTrips());
        unawaited(_restorePendingCashSettlement());
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
    _cancelLocationSubscription();
    unawaited(_realtimeEventsSubscription?.cancel());
    _realtimeEventsSubscription = null;
    unawaited(_realtimeClient.stop());
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
    final isOnline = BlocProvider.of<DashboardCubit>(context).state.isOnline;
    _syncPulseAnimation(isOnline);
    _startRequestCountdownTimer();
    _scheduleActiveTripNavigation();
    unawaited(_showIncomingRequest());
    unawaited(_resumeForegroundWork());
  }

  Future<void> _resumeForegroundWork() async {
    await _loadActiveTrips();
    if (!mounted || !_isForeground) return;
    await BlocProvider.of<RideFlowCubit>(context).syncAuthoritativeRideState();
    if (!mounted || !_isForeground) return;
    await _restorePendingCashSettlement();
    if (!mounted || !_isForeground) return;
    await _refreshLocationAfterResume();
  }

  Future<void> _loadActiveTrips() async {
    if (!mounted || !_isForeground) return;
    await BlocProvider.of<DashboardCubit>(context)
        .loadDispatchSnapshot(includeOffers: false, silent: true);
  }

  Future<void> _restorePendingCashSettlement() async {
    if (!mounted || _isRestoringPendingCashSettlement) return;
    _isRestoringPendingCashSettlement = true;
    try {
      final ride = await BlocProvider.of<RideFlowCubit>(context)
          .restorePendingCashSettlement();
      if (!mounted || ride == null) return;

      final fare = ride.farePesos;
      if (fare == null || fare <= 0) {
        return;
      }

      final duration = ride.durationMinutes;
      context.pushReplacementNamed(
        ActiveRideRoutes.fareSummary,
        extra: {
          'rideId': ride.id,
          'bookingReference': ride.bookingReference,
          'pickup': ride.pickupName,
          'dropoff': ride.dropoffName,
          'distance': ride.distanceKm ?? 0,
          'fare': fare,
          'duration': duration == null
              ? 'Duration unavailable'
              : '${duration.toStringAsFixed(0)} min',
        },
      );
    } finally {
      _isRestoringPendingCashSettlement = false;
    }
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
      final position = await LocationService.getCurrentPosition();
      if (!mounted) return;
      final cubit = BlocProvider.of<DashboardCubit>(context);
      if (!cubit.state.isOnline || position == null) return;

      await cubit.refreshOnlinePresence(
        lat: position.latitude,
        lng: position.longitude,
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
    } finally {
      _isResumingOnline = false;
    }
  }

  void _refreshRequestCountdowns() {
    if (!mounted || !_isForeground) return;
    BlocProvider.of<DashboardCubit>(context).removeExpiredRideOffers();
  }

  void _startRequestCountdownTimer() {
    if (!_isForeground || _requestCountdownTimer != null) return;
    _requestCountdownTimer = Timer.periodic(
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
    if (!BlocProvider.of<DashboardCubit>(context).state.isOnline) return;

    if (event is RideStatusChangedEvent) {
      _handleRideStatusChanged(event);
      return;
    }

    // Direct requests already carry the target driver's topic. Refresh the
    // authoritative offers immediately instead of waiting for the fallback
    // polling interval.
    if (event is RideOfferCreatedEvent) {
      unawaited(IncomingRequestAlert.play());
      unawaited(_pollRideData(_pollGeneration));
      return;
    }
    if (event is RideOfferUpdatedEvent) {
      final payload = event.envelope.payload;
      final sessionId =
          valueAsString(payload['session_id']) ??
          (payload['session'] is Map
              ? valueAsString((payload['session'] as Map)['id'])
              : null);
      final session = payload['session'];
      final wasClosed =
          session is Map &&
          {
            'cancelled',
            'canceled',
          }.contains(valueAsString(session['status'])?.toLowerCase());
      final reason = valueAsString(payload['reason']);
      if (reason == 'another_driver_selected' || wasClosed) {
        BlocProvider.of<DashboardCubit>(context)
            .resolveSubmittedOffer(sessionId);
      }

      unawaited(_pollRideData(_pollGeneration));
      return;
    }
    if (event is! RideMatchedEvent) return;

    final rawRide = event.envelope.payload['ride'];
    if (rawRide is! Map) {
      unawaited(_pollRideData(_pollGeneration));
      return;
    }

    final ride = Map<String, dynamic>.from(rawRide);
    final rideId = valueAsString(ride['id']) ?? event.envelope.scope.rideId;
    if (rideId == null) return;

    final status = valueAsString(ride['status']) ?? 'accepted';
    if (!_isActiveTripStatus(status)) return;
    ride['id'] = rideId;
    ride['status'] = status;

    BlocProvider.of<DashboardCubit>(context)
        .mergeActiveRide(RideSnapshot.fromJson(ride, fallbackId: rideId));
  }

  void _handleRideStatusChanged(RideStatusChangedEvent event) {
    final rawRide = event.envelope.payload['ride'];
    final ride = rawRide is Map ? Map<String, dynamic>.from(rawRide) : null;
    final status =
        valueAsString(ride?['status']) ??
        valueAsString(event.envelope.payload['status']);
    if (status == null) return;
    final terminalStatus = RideStatus.fromString(status);
    if (!terminalStatus.isTerminal) return;

    final rideId = event.envelope.scope.rideId ?? valueAsString(ride?['id']);
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
    _isHandlingRideTerminal = true;
    unawaited(_showRideTerminalDialog(terminal));
  }

  Future<void> _showRideTerminalDialog(RideFlowTerminal terminal) async {
    try {
      if (!mounted) return;
      final (title, message) = switch (terminal.status) {
        'completed' => (
          'Trip already complete',
          'This trip has already been completed. You have been returned to the dispatch queue.',
        ),
        'not_found' => (
          'Trip unavailable',
          'This trip is no longer available. You have been returned to the dispatch queue.',
        ),
        _ => (
          'Trip canceled',
          'This trip was canceled. You have been returned to the dispatch queue.',
        ),
      };
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Back to dispatch'),
            ),
          ],
        ),
      );
      if (mounted) context.goNamed(DashboardRoutes.dashboard);
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
    final position = LocationService.lastPosition;
    if (!cubit.state.isOnline || position == null) return;

    _isRefreshingPresence = true;
    try {
      await cubit.refreshOnlinePresence(
        lat: position.latitude,
        lng: position.longitude,
      );
    } finally {
      _isRefreshingPresence = false;
    }
  }

  void _suspendForegroundWork() {
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

      await BlocProvider.of<DashboardCubit>(context).toggleOnline(
        requestedOnline: requestedOnline,
        lat: position?.latitude ?? 0,
        lng: position?.longitude ?? 0,
      );
    } finally {
      if (mounted && context.mounted) {
        final resolvedOnline = BlocProvider.of<DashboardCubit>(context)
            .state
            .isOnline;
        _pendingOnline = null;
        if (resolvedOnline) {
          _startPolling();
          if (LocationService.lastPosition == null) {
            unawaited(LocationService.getCurrentPosition());
          }
        }
        setState(() => _isTogglingOnline = false);
      }
    }
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

  Future<void> _showIncomingRequest() async {
    if (!mounted ||
        _isShowingRequest ||
        !_isForeground ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final cubit = BlocProvider.of<DashboardCubit>(context);
    final state = cubit.state;
    if (!state.isOnline ||
        state.hasActiveRide ||
        (state.activeBids.isEmpty && state.submittedOffers.isEmpty)) {
      return;
    }
    final sessionId = valueAsString(
      (state.submittedOffers.isNotEmpty
          ? state.submittedOffers.first
          : state.activeBids.first)['id'],
    );
    if (sessionId == null) return;
    _isShowingRequest = true;
    try {
      await Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) =>
              IncomingRideRequestPage(cubit: cubit, sessionId: sessionId),
        ),
      );
    } finally {
      _isShowingRequest = false;
    }
    if (mounted) {
      _scheduleActiveTripNavigation();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_showIncomingRequest());
      });
    }
  }

  void _scheduleActiveTripNavigation() {
    if (_tripNavigationScheduled || !mounted) return;
    _tripNavigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tripNavigationScheduled = false;
      if (mounted) unawaited(_openActiveTrip());
    });
  }

  Future<void> _openActiveTrip({bool retry = false}) async {
    if (!mounted ||
        !_isForeground ||
        _isOpeningTrip ||
        _isShowingRequest ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final trip = BlocProvider.of<DashboardCubit>(context).state.activeRide;
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
    var opened = false;
    try {
      opened = await _resumeTrip(trip);
    } catch (_) {
      opened = false;
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningTrip = false;
          if (!opened) {
            _tripNavigationError = 'Your trip could not be opened. Refresh its status and try again.';
          }
        });
      }
    }
  }

  Future<bool> _resumeTrip(RideSnapshot trip) async {
    final rideId = trip.id;
    final rideFlowCubit = BlocProvider.of<RideFlowCubit>(context);
    var resolvedTrip = await BlocProvider.of<DashboardCubit>(context)
        .fetchAuthoritativeRide(trip.id);
    if (resolvedTrip == null) return false;
    if (!mounted || !context.mounted) return false;
    if (await _discardTerminalTrip(resolvedTrip, rideId)) return true;
    if (!mounted || !context.mounted) return false;
    if (!_reviewedTripIds.contains(rideId) &&
        resolvedTrip.needsRecoveryReview(DateTime.now())) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Review this trip'),
          content: Text(
            resolvedTrip!.status == 'in_transit'
                ? 'This trip has been open longer than expected. Confirm the trip status with your passenger before continuing.'
                : 'This pickup has been waiting longer than expected. Check with the passenger, then continue or use the cancellation action on the trip screen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Open trip'),
            ),
          ],
        ),
      );
      if (!mounted || !context.mounted) return false;
      _reviewedTripIds.add(rideId);
      // The passenger may cancel while the review is open.
      resolvedTrip = await BlocProvider.of<DashboardCubit>(context)
          .fetchAuthoritativeRide(rideId);
      if (!mounted || !context.mounted || resolvedTrip == null) return false;
      if (await _discardTerminalTrip(resolvedTrip, rideId)) return true;
      if (!mounted || !context.mounted) return false;
    }
    final fare = resolvedTrip.farePesos;
    final distance = resolvedTrip.distanceKm;
    final duration = resolvedTrip.durationMinutes;
    if (fare == null || distance == null || duration == null) {
      return false;
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
    if (!resumed || !mounted || !context.mounted) return false;

    context.pushNamed(
      ActiveRideRoutes.trip,
      extra: {
        'pickup': resolvedTrip.pickupName,
        'dropoff': resolvedTrip.dropoffName,
        'distance': distance,
        'fare': fare,
        'duration': '${duration.toStringAsFixed(0)} min',
      },
    );
    return true;
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
          listenWhen: (previous, current) =>
              previous.activeBids != current.activeBids ||
              previous.submittedOffers != current.submittedOffers ||
              previous.isOnline != current.isOnline,
          listener: (_, _) => unawaited(_showIncomingRequest()),
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
            previous.activeRide != current.activeRide ||
            previous.activeBids != current.activeBids ||
            previous.submittedOffers != current.submittedOffers,
        builder: (context, state) {
          final activeRide = state.activeRide;
          if (activeRide != null && ModalRoute.of(context)?.isCurrent == true) {
            _scheduleActiveTripNavigation();
          }
          final dashboardMessage = state.errorMessage;
          final showDashboardError =
              dashboardMessage != null &&
              !AppNetworkStatusScope.isUnavailableOf(context);
          return Column(
            children: [
              if (showDashboardError)
                AppStatusBanner(
                  isVisible: true,
                  message: dashboardMessage,
                  tone: AppStatusBannerTone.error,
                  actionLabel: 'Dismiss',
                  onAction: () =>
                      BlocProvider.of<DashboardCubit>(context).dismissError(),
                ),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: showDashboardError,
                  child: Scaffold(
                    appBar: AppBar(
                      automaticallyImplyLeading: false,
                      backgroundColor: context.canvasColor,
                      titleSpacing: 20,
                      toolbarHeight: 76,
                      title: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EasyRide',
                            style: context.textStyles.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.sm / 2),
                          Text('Driver', style: context.textStyles.labelMedium),
                        ],
                      ),
                    ),
                    body: SafeArea(
                      top: false,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppLayout.contentMaxWidth,
                          ),
                          child: RefreshIndicator(
                            onRefresh: () async {
                              await Future.wait([
                                BlocProvider.of<DashboardCubit>(context)
                                    .loadStats(),
                                _loadActiveTrips(),
                              ]);
                            },
                            child: CustomScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                SliverList.list(
                                  children: [
                                    const SizedBox(height: 8),
                                    _buildOnlineCardBanner(context, state),
                                    const SizedBox(height: 16),
                                    _buildStatsRow(context, state),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                                if (activeRide != null)
                                  SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                          AppSpacing.lg,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_tripNavigationError ==
                                                null) ...[
                                              const CircularProgressIndicator(),
                                              const SizedBox(
                                                height: AppSpacing.md,
                                              ),
                                              const Text('Opening your trip…'),
                                            ] else ...[
                                              Text(
                                                _tripNavigationError!,
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(
                                                height: AppSpacing.md,
                                              ),
                                              FilledButton(
                                                onPressed: () => unawaited(
                                                  _openActiveTrip(retry: true),
                                                ),
                                                child: const Text('Try again'),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Center(
                                        child: _buildStatusIndicator(state),
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
      onRetry: () =>
          unawaited(BlocProvider.of<DashboardCubit>(context).loadStats()),
    );
  }

  Widget _buildStatusIndicator(DashboardState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          state.isOnline ? 'Ready for your next ride' : "You're offline",
          textAlign: TextAlign.center,
          style: context.textStyles.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          state.isOnline
              ? 'New ride requests will appear here.'
              : 'Switch online when you’re ready to drive.',
          textAlign: TextAlign.center,
          style: context.textStyles.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

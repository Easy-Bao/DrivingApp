import 'package:driver_app/src/features/active_ride/active_ride.dart';

import 'dart:async';
import 'dart:developer' as dev;

import 'package:maps/maps.dart';
import 'package:driver_app/src/features/dashboard/presentation/formatters/driver_dashboard_value_formatters.dart';
import 'package:foundation/foundation.dart';
import 'package:driver_app/src/features/dashboard/presentation/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver_app/src/features/dashboard/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:driver_app/src/features/dashboard/presentation/widgets/driver_dashboard/driver_dashboard_stats_row_widget.dart';
import 'package:driver_app/src/features/dashboard/presentation/widgets/driver_dashboard/driver_dashboard_feed_widgets.dart';
import 'package:driver_app/src/features/location/presentation/bloc/location_access/driver_location_access_cubit.dart';
import 'package:driver_app/src/features/location/presentation/bloc/location_access/driver_location_access_state.dart';
import 'package:driver_app/src/features/profile/profile_routes.dart';
import 'package:driver_app/src/features/active_ride/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:driver_app/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:geolocator/geolocator.dart';
import 'package:driver_app/src/features/active_ride/active_ride_routes.dart';
import 'package:design_system/design_system.dart';

bool _isActiveDriverTripStatus(Object? value) {
  return const {
    'assigned',
    'accepted',
    'arrived',
    'in_transit',
  }.contains(dashboardValueAsString(value));
}

class DriverDashboardPage extends StatefulWidget {
  final AppLifecycleCoordinator lifecycleCoordinator;

  const DriverDashboardPage({super.key, required this.lifecycleCoordinator});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _availabilityCtrl;
  Timer? _rideTriggerTimer;
  Timer? _presenceHeartbeatTimer;
  Timer? _locationAccessPoller;
  Timer? _requestCountdownTimer;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<RealtimeEvent>? _realtimeEventsSubscription;
  late final StreamSubscription<AppLifecycleStatus> _lifecycleSubscription;
  RealtimeWebSocketClient? _realtimeClient;
  LiveMapBloc? _liveMapBloc;
  bool _isTogglingOnline = false;
  bool _isResumingOnline = false;
  bool _isRefreshingPresence = false;
  bool? _pendingOnline;
  String? _submittingBidId;
  String? _completingTripId;
  int _pollGeneration = 0;
  int _locationAccessFailures = 0;
  bool _isCheckingLocationAccess = false;
  bool _isForcingOfflineForLocationLoss = false;
  bool _isForeground = true;

  static const _locationAccessPollInterval = Duration(seconds: 5);
  static const _locationAccessFailureThreshold = 2;

  @override
  void initState() {
    super.initState();
    _isForeground = widget.lifecycleCoordinator.isForeground;
    _lifecycleSubscription = widget.lifecycleCoordinator.changes.listen(
      _onLifecycleChanged,
    );
    _liveMapBloc = Modular.get<LiveMapBloc>();
    _realtimeClient = Modular.get<RealtimeWebSocketClient>();
    _realtimeEventsSubscription = _realtimeClient!.events.listen(
      _handleRealtimeEvent,
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _availabilityCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _startRequestCountdownTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final s = BlocProvider.of<DashboardCubit>(context).state;
        _availabilityCtrl.value = s.isOnline ? 1 : 0;
        _startLocationAccessMonitoring();
        unawaited(_loadActiveTrips());
        if (s.isOnline) {
          unawaited(_resumeOnlineTelemetry());
        }
      }
    });
  }

  @override
  void dispose() {
    unawaited(_lifecycleSubscription.cancel());
    _pulseCtrl.dispose();
    _availabilityCtrl.dispose();
    _rideTriggerTimer?.cancel();
    _presenceHeartbeatTimer?.cancel();
    _locationAccessPoller?.cancel();
    _requestCountdownTimer?.cancel();
    _locationSubscription?.cancel();
    _realtimeEventsSubscription?.cancel();
    final realtimeClient = _realtimeClient;
    if (realtimeClient != null) {
      unawaited(realtimeClient.stop());
    }
    _pollGeneration++;
    unawaited(_liveMapBloc?.close());
    super.dispose();
  }

  void _onLifecycleChanged(AppLifecycleStatus status) {
    final isForeground = status == AppLifecycleStatus.foreground;
    if (!isForeground) {
      if (_isForeground) {
        _isForeground = false;
        _suspendForegroundWork();
      }
      return;
    }

    if (_isForeground || !mounted) return;
    _isForeground = true;
    _startRequestCountdownTimer();
    unawaited(_resumeForegroundWork());
  }

  Future<void> _resumeForegroundWork() async {
    await _loadActiveTrips();
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
        await BlocProvider.of<DriverLocationAccessCubit>(context).refresh();
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

      final presenceRestored = await cubit.refreshOnlinePresence(
        lat: position.latitude,
        lng: position.longitude,
      );
      if (!mounted || !cubit.state.isOnline) return;
      if (presenceRestored) _publishCurrentLocation();
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

  void _publishCurrentLocation() {
    final position = LocationService.lastPosition;
    if (position == null) return;
    _liveMapBloc?.add(
      DispatchTelemetryLocationEvent(
        lat: position.latitude,
        lng: position.longitude,
      ),
    );
  }

  void _startPolling() {
    if (!_isForeground) return;
    final pollGeneration = ++_pollGeneration;
    _startLocationAccessMonitoring();
    _locationSubscription?.cancel();
    _locationSubscription = LocationService.getPositionStream().listen(
      (pos) {
        _liveMapBloc?.add(
          DispatchTelemetryLocationEvent(lat: pos.latitude, lng: pos.longitude),
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
    final realtimeClient = _realtimeClient;
    if (realtimeClient == null) return;
    try {
      await realtimeClient.start();
    } catch (error) {
      dev.log('Unable to start driver ride realtime updates: $error');
    }
  }

  void _handleRealtimeEvent(RealtimeEvent event) {
    if (!mounted || !_isForeground) return;
    if (!BlocProvider.of<DashboardCubit>(context).state.isOnline) return;

    // Direct requests already carry the target driver's topic. Refresh the
    // authoritative offers immediately instead of waiting for the fallback
    // polling interval.
    if (event is RideOfferCreatedEvent || event is RideOfferUpdatedEvent) {
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
    final rideId =
        dashboardValueAsString(ride['id']) ?? event.envelope.scope.rideId;
    if (rideId == null) return;

    final status = dashboardValueAsString(ride['status']) ?? 'accepted';
    if (!_isActiveDriverTripStatus(status)) return;
    ride['id'] = rideId;
    ride['status'] = status;

    BlocProvider.of<DashboardCubit>(context).mergeActiveTrip(ride);
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
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _rideTriggerTimer?.cancel();
    _rideTriggerTimer = null;
    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = null;
    _stopLocationAccessMonitoring();
    final realtimeClient = _realtimeClient;
    if (realtimeClient != null) {
      unawaited(realtimeClient.stop());
    }
    if (mounted && clearActiveBids) {
      BlocProvider.of<DashboardCubit>(context).clearActiveBids();
    }
  }

  Future<void> _toggleOnline(BuildContext context, bool requestedOnline) async {
    if (_isTogglingOnline) return;
    setState(() {
      _isTogglingOnline = true;
      _pendingOnline = requestedOnline;
    });
    if (requestedOnline) {
      _availabilityCtrl.forward();
    } else {
      _availabilityCtrl.reverse();
    }

    try {
      if (requestedOnline && await _hasReadyLocationAccess(context) == false) {
        if (context.mounted) {
          unawaited(
            BlocProvider.of<DriverLocationAccessCubit>(context).enable(),
          );
        }
        return;
      }

      var position = LocationService.lastPosition;
      if (requestedOnline) {
        position = await LocationService.getCurrentPosition() ?? position;
      }

      if (!context.mounted) return;

      if (requestedOnline && position == null) {
        CustomToast.show(
          context,
          'Your location is not ready yet. Try again in a moment.',
          isError: true,
        );
        return;
      }

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
          _availabilityCtrl.forward();
          _publishCurrentLocation();
          _startPolling();
        } else {
          _availabilityCtrl.reverse();
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
      if (context.mounted) {
        CustomToast.show(
          context,
          ErrorHandler.getErrorMessage(error, stackTrace),
          isError: true,
        );
      }
      return false;
    }
  }

  Future<void> _acceptBid(Map<String, dynamic> bid) async {
    if (_submittingBidId != null) return;
    final cubit = BlocProvider.of<DashboardCubit>(context);
    final activeTrips = cubit.state.activeTrips;
    if (activeTrips.length >= DriverDashboardSectionLabel.maximumActiveRides) {
      CustomToast.show(
        context,
        'You cannot accept more than '
        '${DriverDashboardSectionLabel.maximumActiveRides} concurrent rides.',
        isError: true,
      );
      return;
    }
    final hasPriority = activeTrips.any((t) => t['ride_type'] == 'Bao Premium');
    if (hasPriority) {
      CustomToast.show(
        context,
        'You are locked into a Priority Ride.',
        isError: true,
      );
      return;
    }
    if (bid['ride_type'] == 'Bao Premium' && activeTrips.isNotEmpty) {
      CustomToast.show(
        context,
        'Cannot accept a Priority Ride while having other active rides.',
        isError: true,
      );
      return;
    }

    final sessionId = dashboardValueAsString(bid['id']);
    final fare = dashboardFareInPesos(bid);
    if (sessionId == null || fare == null) return;

    if (mounted) setState(() => _submittingBidId = sessionId);
    try {
      final success = await cubit.submitRideOffer(
        sessionId: sessionId,
        farePesos: fare,
      );

      if (mounted) {
        if (!success && cubit.state.errorMessage == null) {
          CustomToast.show(context, 'Failed to submit offer.', isError: true);
        }
      }
    } catch (error) {
      if (mounted) {
        CustomToast.show(
          context,
          'Unable to submit the offer. Please try again.',
          isError: true,
        );
      }
      debugPrint('Unable to submit driver offer: $error');
    } finally {
      if (mounted) setState(() => _submittingBidId = null);
    }
  }

  Future<RideSnapshot> _authoritativeTrip(
    Map<String, dynamic> trip,
    String rideId,
  ) async {
    final ride = await BlocProvider.of<DashboardCubit>(context)
        .fetchAuthoritativeRide(rideId);
    if (ride != null) return ride;
    return RideDto.fromJson(trip, fallbackId: rideId).toDomain();
  }

  Future<void> _resumeTrip(Map<String, dynamic> trip) async {
    final rideId = dashboardValueAsString(trip['id']);
    if (rideId == null) return;

    final resolvedTrip = await _authoritativeTrip(trip, rideId);
    if (!mounted) return;
    final fare = resolvedTrip.farePesos;
    final distance = resolvedTrip.distanceKm;
    final duration = resolvedTrip.durationMinutes;
    if (fare == null || distance == null || duration == null) {
      CustomToast.show(
        context,
        'Trip details are unavailable. Please try again.',
        isError: true,
      );
      return;
    }
    final status = resolvedTrip.status;
    String routeName = ActiveRideRoutes.pickupNavigation;
    if (status == 'arrived') {
      routeName = ActiveRideRoutes.waitingPassenger;
    } else if (status == 'in_transit') {
      routeName = ActiveRideRoutes.inTransit;
    }

    BlocProvider.of<RideFlowCubit>(context).resumeRide(
      rideId: rideId,
      status: resolvedTrip.status.isEmpty ? 'accepted' : resolvedTrip.status,
      passengerName: resolvedTrip.passengerName ?? 'Passenger',
      passengerId: resolvedTrip.passengerId,
      distanceKm: resolvedTrip.distanceKm,
      pickupLat: resolvedTrip.pickupLatitude,
      pickupLng: resolvedTrip.pickupLongitude,
      destLat: resolvedTrip.dropoffLatitude,
      destLng: resolvedTrip.dropoffLongitude,
    );

    context.pushNamed(
      routeName,
      extra: {
        'pickup': resolvedTrip.pickupName,
        'dropoff': resolvedTrip.dropoffName,
        'distance': distance,
        'fare': fare,
        'duration': '${duration.toStringAsFixed(0)} min',
      },
    );
  }

  Future<void> _completeTripFromDashboard(Map<String, dynamic> trip) async {
    if (_completingTripId != null) return;
    final rideId = dashboardValueAsString(trip['id']);
    if (rideId == null) return;
    final resolvedTrip = await _authoritativeTrip(trip, rideId);
    if (!mounted) return;
    final fare = resolvedTrip.farePesos;
    final distance = resolvedTrip.distanceKm;
    final duration = resolvedTrip.durationMinutes;
    if (fare == null || distance == null || duration == null) return;

    if (mounted) setState(() => _completingTripId = rideId);
    try {
      final cubit = BlocProvider.of<RideFlowCubit>(context);
      cubit.resumeRide(
        rideId: rideId,
        status: resolvedTrip.status.isEmpty ? 'accepted' : resolvedTrip.status,
        passengerName: resolvedTrip.passengerName ?? 'Passenger',
        passengerId: resolvedTrip.passengerId,
        distanceKm: resolvedTrip.distanceKm,
        pickupLat: resolvedTrip.pickupLatitude,
        pickupLng: resolvedTrip.pickupLongitude,
        destLat: resolvedTrip.dropoffLatitude,
        destLng: resolvedTrip.dropoffLongitude,
      );

      final finalFare = await cubit.completeRide();
      if (finalFare == null) {
        if (mounted) {
          CustomToast.show(
            context,
            'Unable to complete the trip. Please try again.',
            isError: true,
          );
        }
        return;
      }
      if (!mounted) return;

      context.pushReplacementNamed(
        ActiveRideRoutes.fareSummary,
        extra: {
          'pickup': resolvedTrip.pickupName,
          'dropoff': resolvedTrip.dropoffName,
          'distance': distance,
          'fare': finalFare,
          'duration': '${duration.toStringAsFixed(0)} min',
        },
      );
    } finally {
      if (mounted) setState(() => _completingTripId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DashboardCubit, DashboardState>(
          listenWhen: (previous, current) =>
              previous.isOnline != current.isOnline,
          listener: (context, state) {
            if (state.isOnline) {
              _availabilityCtrl.forward();
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
              _availabilityCtrl.reverse();
              _stopPolling();
            }
          },
        ),
        BlocListener<DriverLocationAccessCubit, DriverLocationAccessViewState>(
          listenWhen: (_, current) =>
              current is DriverLocationAccessUnavailable,
          listener: (context, _) {
            if (BlocProvider.of<DashboardCubit>(context).state.isOnline) {
              unawaited(_forceOfflineForLocationLoss());
            }
          },
        ),
      ],
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          final activeTrips = state.activeTrips;
          final activeBids = state.activeBids;
          final showFeed =
              activeTrips.isNotEmpty ||
              (state.isOnline && activeBids.isNotEmpty);
          return Scaffold(
            backgroundColor: context.canvasColor,
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
                    'BaoRide',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: context.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Driver',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: IconButton(
                    tooltip: 'Account',
                    onPressed: () => context.pushNamed(ProfileRoutes.account),
                    icon: const Icon(LucideIcons.user_round),
                    style: IconButton.styleFrom(
                      backgroundColor: context.colorScheme.onSurface.withValues(
                        alpha: 0.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildOnlineCardBanner(context, state),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    DriverDashboardErrorCard(message: state.errorMessage!),
                  ],
                  const SizedBox(height: 16),
                  _buildStatsRow(state),
                  const SizedBox(height: 16),
                  if (showFeed)
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          if (activeTrips.isNotEmpty) ...[
                            DriverDashboardSectionLabel.activeRides(
                              activeRideCount: activeTrips.length,
                            ),
                            const SizedBox(height: 10),
                            ...activeTrips.asMap().entries.map(
                              (entry) => DriverActiveTripCard(
                                trip: entry.value,
                                queueIndex: entry.key,
                                hasCurrentTransitRide: activeTrips.any(
                                  (activeTrip) =>
                                      activeTrip['status'] == 'in_transit',
                                ),
                                isCompletingTrip:
                                    _completingTripId ==
                                    dashboardValueAsString(entry.value['id']),
                                onResume: () => _resumeTrip(entry.value),
                                onComplete: () =>
                                    _completeTripFromDashboard(entry.value),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (activeBids.isNotEmpty) ...[
                            const DriverDashboardSectionLabel(
                              'Incoming Requests',
                            ),
                            const SizedBox(height: 10),
                            ...activeBids.map(
                              (bid) => DriverPoolBidCard(
                                bid: bid,
                                submittingBidId: _submittingBidId,
                                onDecline: () =>
                                    BlocProvider.of<DashboardCubit>(context)
                                        .removeActiveBid(
                                          dashboardValueAsString(bid['id']),
                                        ),
                                onAccept: () => _acceptBid(bid),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  else ...[
                    const Spacer(),
                    _buildStatusIndicator(state),
                    const Spacer(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOnlineCardBanner(BuildContext context, DashboardState state) {
    final isOnline = _pendingOnline ?? state.isOnline;
    final locationReady = context.select<DriverLocationAccessCubit, bool>(
      (cubit) => cubit.state is DriverLocationAccessReady,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) => AnimatedBuilder(
          animation: _availabilityCtrl,
          builder: (context, _) {
            final fillWidth = constraints.maxWidth * _availabilityCtrl.value;
            return ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerHighest,
                  border: isOnline
                      ? null
                      : Border.all(color: context.colorScheme.outlineVariant),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: isOnline ? 0 : null,
                      right: isOnline ? null : 0,
                      width: fillWidth,
                      child: ColoredBox(color: context.colorScheme.primary),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isOnline ? "You're online" : "You're offline",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isOnline
                                      ? context.colorScheme.onPrimary
                                      : context.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isOnline
                                    ? 'Looking for rides nearby'
                                    : 'Go online to receive rides',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isOnline
                                      ? context.colorScheme.onPrimary
                                      : context.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          _buildAvailabilitySwitch(
                            context,
                            isOnline,
                            _availabilityCtrl.value,
                            locationReady,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvailabilitySwitch(
    BuildContext context,
    bool isOnline,
    double animationProgress,
    bool locationReady,
  ) {
    final trackColor = isOnline
        ? Color.lerp(
            context.colorScheme.primary.withValues(alpha: 0.16),
            context.colorScheme.onPrimary.withValues(alpha: 0.28),
            animationProgress,
          )!
        : context.colorScheme.outlineVariant;
    final thumbColor = isOnline
        ? Color.lerp(
            context.colorScheme.primary,
            context.colorScheme.onPrimary,
            animationProgress,
          )!
        : context.colorScheme.onSurfaceVariant;

    return SizedBox(
      width: 56,
      height: 32,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: _isTogglingOnline
            ? Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isOnline
                        ? context.colorScheme.onPrimary
                        : context.colorScheme.onSurface,
                  ),
                ),
              )
            : Switch(
                value: isOnline,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeThumbColor: thumbColor,
                activeTrackColor: context.colorScheme.onPrimary.withValues(
                  alpha: 0,
                ),
                inactiveThumbColor: thumbColor,
                inactiveTrackColor: context.colorScheme.onPrimary.withValues(
                  alpha: 0,
                ),
                onChanged: (locationReady || isOnline)
                    ? (value) => unawaited(_toggleOnline(context, value))
                    : null,
              ),
      ),
    );
  }

  Widget _buildStatsRow(DashboardState state) {
    return DriverDashboardStatsRowWidget(
      isLoadingStats: state.isLoadingStats,
      earnings: state.earnings,
      completedTrips: state.completedTrips,
      errorMessage: state.errorMessage == null ? state.statsErrorMessage : null,
      onRetry: () =>
          unawaited(BlocProvider.of<DashboardCubit>(context).loadStats()),
    );
  }

  Widget _buildStatusIndicator(DashboardState state) {
    if (state.isOnline) {
      return RepaintBoundary(
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, _) {
            final pulseOpacity = 0.4 + _pulseCtrl.value * 0.6;
            final accentColor = context.colorScheme.primary.withValues(
              alpha: context.colorScheme.primary.a * pulseOpacity,
            );
            return Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: context.colorScheme.secondaryContainer.withValues(
                      alpha: 0.22 * pulseOpacity,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.radar,
                      size: 32,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Looking for rides...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: context.colorScheme.onSurface.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              LucideIcons.moon,
              size: 32,
              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "You're offline",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Go online to start receiving rides.',
          style: TextStyle(
            fontSize: 14,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

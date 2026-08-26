import 'dart:async';
import 'dart:developer' as dev;

import 'package:driver_app/src/core/location/location.dart';
import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:driver_app/src/core/formatters/driver_value_formatters.dart';
import 'package:shared_core/shared_core.dart';
import 'package:driver_app/src/features/home/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver_app/src/features/home/bloc/dashboard/dashboard_state.dart';
import 'package:driver_app/src/features/home/view/widgets/driver_dashboard/driver_dashboard_stats_row_widget.dart';
import 'package:driver_app/src/features/home/view/widgets/driver_dashboard/driver_dashboard_feed_widgets.dart';
import 'package:driver_app/src/features/location/location_routes.dart';
import 'package:driver_app/src/features/profile/profile_routes.dart';
import 'package:driver_app/src/features/trip/bloc/live_map/live_map_bloc.dart';
import 'package:driver_app/src/features/trip/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:geolocator/geolocator.dart';
import 'package:driver_app/src/features/trip/trip_routes.dart';
import 'package:shared_ui/shared_ui.dart';

bool _isActiveDriverTripStatus(Object? value) {
  return const {
    'assigned',
    'accepted',
    'arrived',
    'in_transit',
  }.contains(driverValueAsString(value));
}

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _pulseCtrl;
  late final AnimationController _availabilityCtrl;
  Timer? _rideTriggerTimer;
  Timer? _presenceHeartbeatTimer;
  Timer? _locationAccessPoller;
  Timer? _requestCountdownTimer;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<RealtimeEvent>? _realtimeEventsSubscription;
  RealtimeWebSocketClient? _realtimeClient;
  LiveMapBloc? _liveMapBloc;
  bool _isTogglingOnline = false;
  bool _isResumingOnline = false;
  bool _isRefreshingPresence = false;
  bool? _pendingOnline;
  String? _submittingBidId;
  String? _completingTripId;
  int _pollGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    _requestCountdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshRequestCountdowns(),
    );

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
    WidgetsBinding.instance.removeObserver(this);
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      unawaited(_loadActiveTrips());
      unawaited(_refreshLocationAfterResume());
    }
  }

  Future<void> _loadActiveTrips() async {
    if (!mounted) return;
    await BlocProvider.of<DashboardCubit>(
      context,
    ).loadDispatchSnapshot(includeOffers: false, silent: true);
  }

  Future<void> _refreshLocationAfterResume() async {
    if (!mounted) return;
    final accessState = await LocationService.getAccessState();
    if (!mounted) return;
    final dashboardState = BlocProvider.of<DashboardCubit>(context).state;
    if (accessState != LocationAccessState.ready) {
      if (dashboardState.isOnline) {
        await _forceOfflineForLocationLoss();
        if (!mounted) return;
        context.goNamed(DriverLocationRoutes.gate);
      }
      return;
    }

    if (dashboardState.isOnline) {
      await _resumeOnlineTelemetry();
    }
  }

  void _startLocationAccessMonitoring() {
    _locationAccessPoller ??= Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final accessState = await LocationService.getAccessState();
      if (!mounted) return;
      if (accessState == LocationAccessState.ready) {
        timer.cancel();
        _locationAccessPoller = null;
        return;
      }

      if (BlocProvider.of<DashboardCubit>(context).state.isOnline) {
        timer.cancel();
        _locationAccessPoller = null;
        unawaited(_forceOfflineForLocationLoss());
      }
    });
  }

  Future<void> _forceOfflineForLocationLoss() async {
    if (!mounted) return;
    final position = LocationService.lastPosition;
    await BlocProvider.of<DashboardCubit>(
      context,
    ).forceOffline(lat: position?.latitude ?? 0, lng: position?.longitude ?? 0);
    if (mounted) context.goNamed(DriverLocationRoutes.gate);
  }

  Future<void> _resumeOnlineTelemetry() async {
    if (_isResumingOnline) return;
    _isResumingOnline = true;
    try {
      await LocationService.getCurrentPosition();
      if (!mounted) return;
      final position = LocationService.lastPosition;
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
      dev.log('Unable to restore online driver telemetry: $error');
      if (!mounted) return;
      final position = LocationService.lastPosition;
      await BlocProvider.of<DashboardCubit>(context).forceOffline(
        lat: position?.latitude ?? 0,
        lng: position?.longitude ?? 0,
      );
    } finally {
      _isResumingOnline = false;
    }
  }

  void _refreshRequestCountdowns() {
    if (!mounted) return;
    BlocProvider.of<DashboardCubit>(context).removeExpiredRideOffers();
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
    final pollGeneration = ++_pollGeneration;
    _locationSubscription?.cancel();
    _locationSubscription = LocationService.getPositionStream().listen((pos) {
      _liveMapBloc?.add(
        DispatchTelemetryLocationEvent(lat: pos.latitude, lng: pos.longitude),
      );
    });

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
    final realtimeClient = _realtimeClient;
    if (realtimeClient == null) return;
    try {
      await realtimeClient.start();
    } catch (error) {
      dev.log('Unable to start driver ride realtime updates: $error');
    }
  }

  void _handleRealtimeEvent(RealtimeEvent event) {
    if (!mounted) return;
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
        driverValueAsString(ride['id']) ?? event.envelope.scope.rideId;
    if (rideId == null) return;

    final status = driverValueAsString(ride['status']) ?? 'accepted';
    if (!_isActiveDriverTripStatus(status)) return;
    ride['id'] = rideId;
    ride['status'] = status;

    BlocProvider.of<DashboardCubit>(context).mergeActiveTrip(ride);
  }

  Future<void> _pollRideData(int pollGeneration) async {
    if (!mounted ||
        pollGeneration != _pollGeneration ||
        !BlocProvider.of<DashboardCubit>(context).state.isOnline) {
      return;
    }

    await BlocProvider.of<DashboardCubit>(
      context,
    ).loadDispatchSnapshot(silent: true);
    if (mounted && pollGeneration != _pollGeneration) {
      unawaited(_pollRideData(_pollGeneration));
    }
  }

  Future<void> _refreshOnlinePresence() async {
    if (!mounted || _isRefreshingPresence) return;
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

  void _stopPolling() {
    _pollGeneration++;
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _rideTriggerTimer?.cancel();
    _rideTriggerTimer = null;
    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = null;
    final realtimeClient = _realtimeClient;
    if (realtimeClient != null) {
      unawaited(realtimeClient.stop());
    }
    if (mounted) BlocProvider.of<DashboardCubit>(context).clearActiveBids();
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
      if (requestedOnline &&
          await LocationService.getAccessState() != LocationAccessState.ready) {
        if (context.mounted) {
          context.goNamed(DriverLocationRoutes.gate);
        }
        return;
      }

      var position = LocationService.lastPosition;
      if (requestedOnline) {
        position = await LocationService.getCurrentPosition() ?? position;
      }

      if (!context.mounted) return;

      if (requestedOnline && position == null) {
        context.goNamed(DriverLocationRoutes.gate);
        return;
      }

      await BlocProvider.of<DashboardCubit>(context).toggleOnline(
        requestedOnline: requestedOnline,
        lat: position?.latitude ?? 0,
        lng: position?.longitude ?? 0,
      );
    } finally {
      if (mounted && context.mounted) {
        final resolvedOnline = BlocProvider.of<DashboardCubit>(
          context,
        ).state.isOnline;
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

  Future<void> _acceptBid(Map<String, dynamic> bid) async {
    if (_submittingBidId != null) return;
    final cubit = BlocProvider.of<DashboardCubit>(context);
    final activeTrips = cubit.state.activeTrips;
    if (activeTrips.length >= 5) {
      CustomToast.show(
        context,
        'You cannot accept more than 5 concurrent rides.',
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

    final sessionId = driverValueAsString(bid['id']);
    final fare = driverFareInPesos(bid);
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
    final ride = await BlocProvider.of<DashboardCubit>(
      context,
    ).fetchAuthoritativeRide(rideId);
    if (ride != null) return ride;
    return RideSnapshot.fromJson(trip, fallbackId: rideId);
  }

  Future<void> _resumeTrip(Map<String, dynamic> trip) async {
    final rideId = driverValueAsString(trip['id']);
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
    String routeName = TripRoutes.pickupNavigation;
    if (status == 'arrived') {
      routeName = TripRoutes.waitingPassenger;
    } else if (status == 'in_transit') {
      routeName = TripRoutes.inTransit;
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
    final rideId = driverValueAsString(trip['id']);
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
        TripRoutes.fareSummary,
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
    return BlocListener<DashboardCubit, DashboardState>(
      listenWhen: (previous, current) =>
          previous.isOnline != current.isOnline ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        final errorMessage = state.errorMessage;
        if (errorMessage != null) {
          CustomToast.show(context, errorMessage, isError: true);
        }
        if (state.isOnline) {
          _availabilityCtrl.forward();
          // A user-triggered transition already establishes telemetry and
          // starts the background service in the repository. Re-running the
          // full online handshake here creates a duplicate request and can
          // race the first transition. Restored sessions still need the
          // reconciliation performed by _resumeOnlineTelemetry().
          if (!_isTogglingOnline) {
            unawaited(_resumeOnlineTelemetry());
          }
        } else {
          _availabilityCtrl.reverse();
          _stopPolling();
        }
      },
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          final activeTrips = state.activeTrips;
          final activeBids = state.activeBids;
          final showFeed =
              activeTrips.isNotEmpty ||
              (state.isOnline && activeBids.isNotEmpty);
          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: AppTheme.background,
              titleSpacing: 20,
              toolbarHeight: 76,
              title: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BaoRide',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Driver',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.tertiaryColor,
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
                      backgroundColor: AppTheme.primaryColor.withValues(
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
                            DriverDashboardSectionLabel(
                              'Your active rides (__ACTIVE_COUNT__/5)',
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
                                    driverValueAsString(entry.value['id']),
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
                                    BlocProvider.of<DashboardCubit>(
                                      context,
                                    ).removeActiveBid(
                                      driverValueAsString(bid['id']),
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
                  color: AppTheme.neutralColor,
                  border: isOnline
                      ? null
                      : Border.all(color: AppTheme.borderSide),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: isOnline ? 0 : null,
                      right: isOnline ? null : 0,
                      width: fillWidth,
                      child: const ColoredBox(color: AppTheme.primaryColor),
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
                                      ? AppTheme.surface
                                      : AppTheme.primaryColor,
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
                                      ? AppTheme.surface.withValues(alpha: 0.8)
                                      : AppTheme.primaryColor.withValues(
                                          alpha: 0.6,
                                        ),
                                ),
                              ),
                            ],
                          ),
                          _buildAvailabilitySwitch(
                            context,
                            isOnline,
                            _availabilityCtrl.value,
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
  ) {
    final trackColor = isOnline
        ? Color.lerp(
            AppTheme.primaryColor.withValues(alpha: 0.16),
            AppTheme.surface.withValues(alpha: 0.28),
            animationProgress,
          )!
        : AppTheme.borderSide;
    final thumbColor = isOnline
        ? Color.lerp(
            AppTheme.primaryColor,
            AppTheme.surface,
            animationProgress,
          )!
        : AppTheme.primaryColor.withValues(alpha: 0.4);

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
                    color: isOnline ? AppTheme.surface : AppTheme.primaryColor,
                  ),
                ),
              )
            : Switch(
                value: isOnline,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeThumbColor: thumbColor,
                activeTrackColor: AppTheme.surface.withValues(alpha: 0),
                inactiveThumbColor: thumbColor,
                inactiveTrackColor: AppTheme.surface.withValues(alpha: 0),
                onChanged: (value) => _toggleOnline(context, value),
              ),
      ),
    );
  }

  Widget _buildStatsRow(DashboardState state) {
    return DriverDashboardStatsRowWidget(
      isLoadingStats: state.isLoadingStats,
      earnings: state.earnings,
      completedTrips: state.completedTrips,
    );
  }

  Widget _buildStatusIndicator(DashboardState state) {
    if (state.isOnline) {
      return AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, _) => Opacity(
          opacity: 0.4 + _pulseCtrl.value * 0.6,
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.radar,
                    size: 32,
                    color: AppTheme.accent,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Looking for rides...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.accent,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              LucideIcons.moon,
              size: 32,
              color: AppTheme.primaryColor.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "You're offline",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Go online to start receiving rides.',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.primaryColor.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

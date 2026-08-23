import 'dart:async';
import 'dart:developer' as dev;

import 'package:driver_app/src/core/location/location.dart';
import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:driver_app/src/core/formatters/driver_value_formatters.dart';
import 'package:shared_core/shared_core.dart';
import 'package:driver_app/src/features/home/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver_app/src/features/home/bloc/dashboard/dashboard_state.dart';
import 'package:driver_app/src/features/home/domain/entities/driver_dispatch_snapshot.dart';
import 'package:driver_app/src/features/home/domain/repositories/i_dashboard_repository.dart';
import 'package:driver_app/src/features/home/view/widgets/driver_dashboard/driver_dashboard_stats_row_widget.dart';
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

double? _distanceInKm(Map<String, dynamic> value) {
  final distance = value['distance_km'] ?? value['distance'];
  return distance is num && distance >= 0 ? distance.toDouble() : null;
}

bool _isActiveDriverTripStatus(Object? value) {
  return const {
    'assigned',
    'accepted',
    'arrived',
    'in_transit',
  }.contains(driverValueAsString(value));
}

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key, required this.repository});

  final IDashboardRepository repository;

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
  List<Map<String, dynamic>> _activeBids = [];
  List<Map<String, dynamic>> _activeTrips = [];
  LiveMapBloc? _liveMapBloc;
  bool _isTogglingOnline = false;
  bool _isResumingOnline = false;
  bool _isRefreshingPresence = false;
  bool? _pendingOnline;
  String? _submittingBidId;
  String? _completingTripId;
  bool _isPollingRideData = false;
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
    if (!mounted || _isPollingRideData) return;
    _isPollingRideData = true;
    try {
      late DriverDispatchSnapshot snapshot;
      (await widget.repository.getDispatchSnapshot(
        includeOffers: false,
      )).fold((failure) => throw failure, (value) => snapshot = value);
      final trips = snapshot.activeTrips
          .where(_isActiveDriverTripStatus)
          .map(Map<String, dynamic>.from)
          .toList();
      if (mounted) {
        _sortActiveTrips(trips);
        setState(() => _activeTrips = trips);
      }
    } catch (error) {
      dev.log('Unable to recover active driver trips: $error');
    } finally {
      _isPollingRideData = false;
    }
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

    final updatedTrips = List<Map<String, dynamic>>.from(_activeTrips);
    final existingIndex = updatedTrips.indexWhere(
      (trip) => driverValueAsString(trip['id']) == rideId,
    );
    if (existingIndex >= 0) {
      updatedTrips[existingIndex] = {...updatedTrips[existingIndex], ...ride};
    } else {
      updatedTrips.insert(0, ride);
    }
    _sortActiveTrips(updatedTrips);

    setState(() => _activeTrips = updatedTrips);
  }

  void _sortActiveTrips(List<Map<String, dynamic>> trips) {
    trips.sort((a, b) {
      const statusPriority = {
        'in_transit': 0,
        'arrived': 1,
        'accepted': 2,
        'assigned': 2,
      };
      final aPriority = statusPriority[a['status']] ?? 3;
      final bPriority = statusPriority[b['status']] ?? 3;
      if (aPriority != bPriority) return aPriority.compareTo(bPriority);
      return (a['created_at'] as String? ?? '').compareTo(
        b['created_at'] as String? ?? '',
      );
    });
  }

  Future<void> _pollRideData(int pollGeneration) async {
    if (!mounted ||
        pollGeneration != _pollGeneration ||
        _isPollingRideData ||
        !BlocProvider.of<DashboardCubit>(context).state.isOnline) {
      return;
    }

    _isPollingRideData = true;
    try {
      late DriverDispatchSnapshot snapshot;
      (await widget.repository.getDispatchSnapshot()).fold(
        (failure) => throw failure,
        (value) => snapshot = value,
      );
      final trips = snapshot.activeTrips
          .where((ride) => _isActiveDriverTripStatus(ride['status']))
          .map(Map<String, dynamic>.from)
          .toList();
      final bids = snapshot.rideOffers;

      if (!mounted ||
          pollGeneration != _pollGeneration ||
          !BlocProvider.of<DashboardCubit>(context).state.isOnline) {
        return;
      }

      _sortActiveTrips(trips);
      setState(() {
        _activeTrips = trips;
        _activeBids = bids;
      });
    } catch (error) {
      debugPrint('Error polling: $error');
    } finally {
      _isPollingRideData = false;
      if (mounted && pollGeneration != _pollGeneration) {
        unawaited(_pollRideData(_pollGeneration));
      }
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
    if (mounted) {
      setState(() {
        _activeBids = [];
      });
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
    if (_activeTrips.length >= 5) {
      CustomToast.show(
        context,
        'You cannot accept more than 5 concurrent rides.',
        isError: true,
      );
      return;
    }
    final hasPriority = _activeTrips.any(
      (t) => t['ride_type'] == 'Bao Premium',
    );
    if (hasPriority) {
      CustomToast.show(
        context,
        'You are locked into a Priority Ride.',
        isError: true,
      );
      return;
    }
    if (bid['ride_type'] == 'Bao Premium' && _activeTrips.isNotEmpty) {
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
      final result = await widget.repository.submitRideOffer(
        sessionId: sessionId,
        farePesos: fare,
      );
      final success = result.fold((_) => false, (_) => true);

      if (mounted) {
        if (success) {
          setState(() {
            _activeBids.removeWhere(
              (activeBid) => driverValueAsString(activeBid['id']) == sessionId,
            );
          });
        } else {
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
    try {
      RideSnapshot? ride;
      (await widget.repository.fetchRide(
        rideId,
      )).fold((_) {}, (value) => ride = value);
      if (ride != null) return ride!;
    } catch (error) {
      dev.log('Unable to refresh trip $rideId before resuming: $error');
    }
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
          final showFeed =
              _activeTrips.isNotEmpty ||
              (state.isOnline && _activeBids.isNotEmpty);
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
                          if (_activeTrips.isNotEmpty) ...[
                            _buildSectionLabel(
                              'Your active rides (${_activeTrips.length}/5)',
                            ),
                            const SizedBox(height: 10),
                            ..._activeTrips.asMap().entries.map(
                              (entry) =>
                                  _buildActiveTripCard(entry.value, entry.key),
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (_activeBids.isNotEmpty) ...[
                            _buildSectionLabel('Incoming Requests'),
                            const SizedBox(height: 10),
                            ..._activeBids.map(_buildPoolBidCard),
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

  Widget _buildActiveTripCard(Map<String, dynamic> trip, int queueIndex) {
    final status = trip['status'] as String? ?? 'accepted';
    String statusLabel = 'Heading To Passenger';
    Color statusColor = AppTheme.inProgress;
    if (status == 'arrived') {
      statusLabel = 'Waiting For Passenger';
      statusColor = AppTheme.secondaryColor;
    } else if (status == 'in_transit') {
      statusLabel = 'Driving Passenger';
      statusColor = AppTheme.complete;
    }
    final hasCurrentTransitRide = _activeTrips.any(
      (activeTrip) => activeTrip['status'] == 'in_transit',
    );
    final isQueued = hasCurrentTransitRide && status != 'in_transit';
    final tripId = driverValueAsString(trip['id']);
    final isCompleting = tripId != null && _completingTripId == tripId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor == AppTheme.secondaryColor
                        ? AppTheme.primaryColor
                        : statusColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                driverFareInPesos(trip) == null
                    ? '—'
                    : '₱${driverFareInPesos(trip)!.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          if (isQueued) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Queued passenger ${queueIndex + 1} • Start after the current trip',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                LucideIcons.user,
                size: 14,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                driverValueAsString(trip['passenger_name']) ?? '—',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CompactRouteTimelineWidget(
            pickup: driverValueAsString(trip['pickup_name']) ?? '—',
            dropoff: driverValueAsString(trip['dropoff_name']) ?? '—',
          ),
          const SizedBox(height: 14),
          if (status == 'in_transit')
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => _resumeTrip(trip),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.activeControlForeground,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Go to Trip Flow',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: isCompleting
                          ? null
                          : () => _completeTripFromDashboard(trip),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.complete,
                        foregroundColor: AppTheme.activeControlForeground,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: isCompleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.surface,
                              ),
                            )
                          : const Text(
                              'Complete Trip',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: isQueued ? null : () => _resumeTrip(trip),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.activeControlForeground,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: const Text(
                  'Go to Trip Flow',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _refreshRequestCountdowns() {
    if (!mounted || _activeBids.isEmpty) return;
    final activeBids = _activeBids.where((bid) {
      final remaining = _remainingBidSeconds(bid);
      return remaining == null || remaining > 0;
    }).toList();
    setState(() => _activeBids = activeBids);
  }

  int? _remainingBidSeconds(Map<String, dynamic> bid) {
    final rawExpiry = driverValueAsString(bid['expires_at']);
    final expiresAt = rawExpiry == null ? null : DateTime.tryParse(rawExpiry);
    if (expiresAt == null) return null;
    final seconds = expiresAt.difference(DateTime.now()).inSeconds;
    return seconds.clamp(0, 3599).toInt();
  }

  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '$minutes:${remainder.toString().padLeft(2, '0')}';
  }

  Widget _buildPoolBidCard(Map<String, dynamic> bid) {
    final pickup = bid['pickup_name']?.toString() ?? '—';
    final dropoff = bid['dropoff_name']?.toString() ?? '—';
    final fare = driverFareInPesos(bid);
    final distance = _distanceInKm(bid);
    final bidId = driverValueAsString(bid['id']);
    final isSubmitting = bidId != null && _submittingBidId == bidId;
    final remainingSeconds = _remainingBidSeconds(bid);
    final passengerNote = driverValueAsString(bid['passenger_note']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSide),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Ride Request',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.neutralColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.clock_3, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      remainingSeconds == null
                          ? '—'
                          : _formatCountdown(remainingSeconds),
                      key: ValueKey('request-countdown-$bidId'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CompactRouteTimelineWidget(pickup: pickup, dropoff: dropoff),
          if (passengerNote != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppTheme.neutralColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.message_square_text, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      passengerNote,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.borderSide),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                distance == null
                    ? 'Distance unavailable'
                    : '${DistanceFormatter.fromKilometers(distance)} away',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                ),
              ),
              Text(
                fare == null ? '—' : '₱${fare.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submittingBidId != null
                      ? null
                      : () {
                          setState(() {
                            _activeBids.removeWhere(
                              (b) => b['id'] == bid['id'],
                            );
                          });
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppTheme.borderSide),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Decline',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: fare == null || _submittingBidId != null
                      ? null
                      : () => _acceptBid(bid),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const StadiumBorder(),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.surface,
                          ),
                        )
                      : const Text(
                          'Accept',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.surface,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppTheme.primaryColor.withValues(alpha: 0.6),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

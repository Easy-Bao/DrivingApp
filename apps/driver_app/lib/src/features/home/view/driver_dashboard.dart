import 'package:driver_app/src/core/location/location.dart';
import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:driver_app/src/core/formatters/driver_value_formatters.dart';

import 'dart:async';

import 'package:shared_core/shared_core.dart';
import 'package:driver_app/src/features/home/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver_app/src/features/home/bloc/dashboard/dashboard_state.dart';
import 'package:driver_app/src/features/home/view/widgets/driver_dashboard/driver_dashboard_stats_row_widget.dart';
import 'package:driver_app/src/features/profile/profile_routes.dart';
import 'package:driver_app/src/features/trip/bloc/live_map/live_map_bloc.dart';
import 'package:driver_app/src/features/trip/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:geolocator/geolocator.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/trip/data/datasources/bidding_remote_data_source.dart';
import 'package:driver_app/src/features/trip/data/datasources/trip_remote_data_source.dart';
import 'package:driver_app/src/features/trip/trip_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';

double? _distanceInKm(Map<String, dynamic> value) {
  final distance = value['distance_km'] ?? value['distance'];
  return distance is num && distance >= 0 ? distance.toDouble() : null;
}

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _pulseCtrl;
  late final AnimationController _availabilityCtrl;
  Timer? _rideTriggerTimer;
  StreamSubscription<Position>? _locationSubscription;
  List<Map<String, dynamic>> _activeBids = [];
  List<Map<String, dynamic>> _activeTrips = [];
  LiveMapBloc? _liveMapBloc;
  bool _isTogglingOnline = false;
  bool? _pendingOnline;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _liveMapBloc = Modular.get<LiveMapBloc>();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _availabilityCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final s = BlocProvider.of<DashboardCubit>(context).state;
        _availabilityCtrl.value = s.isOnline ? 1 : 0;
        if (s.isOnline) {
          _startPolling();
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
    _locationSubscription?.cancel();
    _liveMapBloc?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      unawaited(_refreshLocationAfterResume());
    }
  }

  Future<void> _refreshLocationAfterResume() async {
    await LocationService.refresh();
    if (!mounted) return;
    final dashboardState = BlocProvider.of<DashboardCubit>(context).state;
    if (dashboardState.isOnline) {
      _startPolling();
    }
  }

  void _startPolling() {
    _locationSubscription?.cancel();
    _locationSubscription = LocationService.getPositionStream().listen((
      pos,
    ) async {
      _liveMapBloc?.add(
        DispatchTelemetryLocationEvent(lat: pos.latitude, lng: pos.longitude),
      );
    });

    _rideTriggerTimer?.cancel();
    _rideTriggerTimer = Timer.periodic(const Duration(seconds: 4), (
      timer,
    ) async {
      if (!mounted) return;
      final s = BlocProvider.of<DashboardCubit>(context).state;
      if (!s.isOnline) {
        timer.cancel();
        return;
      }

      try {
        final driverId =
            await Modular.get<SecureSessionService>().readDriverId() ?? '';
        if (driverId.isEmpty) return;

        final list = await Modular.get<TripRemoteDataSource>().fetchTripHistory(
          driverId,
        );
        List<Map<String, dynamic>> trips = list
            .where((r) {
              final status = r['status'] as String?;
              return status == 'accepted' ||
                  status == 'arrived' ||
                  status == 'in_transit';
            })
            .map((r) => r as Map<String, dynamic>)
            .toList();

        final bidsList = await Modular.get<BiddingRemoteDataSource>()
            .fetchActiveBids(driverId);
        final List<Map<String, dynamic>> bids = bidsList
            .map((b) => b as Map<String, dynamic>)
            .toList();

        if (mounted) {
          trips.sort((a, b) {
            const statusPriority = {
              'in_transit': 0,
              'arrived': 1,
              'accepted': 2,
            };
            final aPriority = statusPriority[a['status']] ?? 3;
            final bPriority = statusPriority[b['status']] ?? 3;
            if (aPriority != bPriority) return aPriority.compareTo(bPriority);
            return (a['created_at'] as String? ?? '').compareTo(
              b['created_at'] as String? ?? '',
            );
          });
          setState(() {
            _activeTrips = trips;
            _activeBids = bids;
          });
        }
      } catch (error) {
        debugPrint('Error polling: $error');
      }
    });
  }

  void _stopPolling() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _rideTriggerTimer?.cancel();
    _rideTriggerTimer = null;
    if (mounted) {
      setState(() {
        _activeTrips = [];
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
      final hasLocationAccess = await LocationPermissionPrompt.ensure(
        context,
        title: 'Stay available for nearby rides',
        message:
            'We use your location to send accurate ride requests and ETAs.',
        secondaryLabel: 'Maybe Later',
      );
      if (!hasLocationAccess || !context.mounted) return;

      var position = LocationService.lastPosition;
      position ??= await LocationService.getCurrentPosition();

      if (!context.mounted) return;

      if (position == null) return;

      await BlocProvider.of<DashboardCubit>(
        context,
      ).toggleOnline(lat: position.latitude, lng: position.longitude);
    } finally {
      if (mounted && context.mounted) {
        final resolvedOnline = BlocProvider.of<DashboardCubit>(
          context,
        ).state.isOnline;
        _pendingOnline = null;
        if (resolvedOnline) {
          _availabilityCtrl.forward();
        } else {
          _availabilityCtrl.reverse();
        }
        setState(() => _isTogglingOnline = false);
      }
    }
  }

  Future<void> _acceptBid(Map<String, dynamic> bid) async {
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

    final driverId =
        await Modular.get<SecureSessionService>().readDriverId() ?? '';
    final prefs = await SharedPreferences.getInstance();
    final driverName = prefs.getString('driver_name') ?? '';
    final vehicleType = prefs.getString('vehicle_type') ?? '';
    final plateNumber = prefs.getString('plate_number') ?? '';

    final sessionId = driverValueAsString(bid['id']);
    final fare = driverFareInPesos(bid);
    if (sessionId == null || fare == null) return;

    final success = await Modular.get<BiddingRemoteDataSource>().placeBid(
      sessionId: sessionId,
      driverId: driverId,
      driverName: driverName,
      plateNumber: plateNumber,
      vehicleType: vehicleType,
      offerPrice: fare,
      proposedFare: fare,
    );

    if (mounted) {
      if (success) {
        CustomToast.show(context, 'Offer submitted! Waiting for passenger...');
      } else {
        CustomToast.show(context, 'Failed to submit offer.', isError: true);
      }
    }
  }

  void _resumeTrip(Map<String, dynamic> trip) {
    final rideId = driverValueAsString(trip['id']);
    final fare = driverFareInPesos(trip);
    final distance = _distanceInKm(trip);
    final duration = (trip['duration_minutes'] as num?)?.toDouble();
    if (rideId == null ||
        fare == null ||
        distance == null ||
        duration == null) {
      return;
    }
    final status = trip['status'] as String?;
    String routeName = TripRoutes.enRoutePickup;
    if (status == 'arrived') {
      routeName = TripRoutes.waitingPassenger;
    } else if (status == 'in_transit') {
      routeName = TripRoutes.inTransit;
    }

    BlocProvider.of<RideFlowCubit>(context).resumeRide(
      rideId: rideId,
      status: driverValueAsString(trip['status']) ?? 'accepted',
      passengerName: driverValueAsString(trip['passenger_name']) ?? 'Passenger',
      distanceKm: (trip['distance_km'] as num?)?.toDouble(),
      pickupLat: SafeParse.toNullableDouble(trip['pickup_latitude']),
      pickupLng: SafeParse.toNullableDouble(trip['pickup_longitude']),
      destLat: SafeParse.toNullableDouble(trip['dropoff_latitude']),
      destLng: SafeParse.toNullableDouble(trip['dropoff_longitude']),
    );

    context.pushNamed(
      routeName,
      extra: {
        'pickup': trip['pickup_name'] ?? 'Pickup',
        'dropoff': trip['dropoff_name'] ?? 'Dropoff',
        'distance': distance,
        'fare': fare,
        'duration': '${duration.toStringAsFixed(0)} min',
      },
    );
  }

  Future<void> _completeTripFromDashboard(Map<String, dynamic> trip) async {
    final rideId = driverValueAsString(trip['id']);
    if (rideId == null) return;
    final fare = driverFareInPesos(trip);
    final distance = _distanceInKm(trip);
    final duration = (trip['duration_minutes'] as num?)?.toDouble();
    if (fare == null || distance == null || duration == null) return;

    final cubit = BlocProvider.of<RideFlowCubit>(context);
    cubit.resumeRide(
      rideId: rideId,
      status: driverValueAsString(trip['status']) ?? 'accepted',
      passengerName: driverValueAsString(trip['passenger_name']) ?? 'Passenger',
      distanceKm: (trip['distance_km'] as num?)?.toDouble(),
      pickupLat: SafeParse.toNullableDouble(trip['pickup_latitude']),
      pickupLng: SafeParse.toNullableDouble(trip['pickup_longitude']),
      destLat: SafeParse.toNullableDouble(trip['dropoff_latitude']),
      destLng: SafeParse.toNullableDouble(trip['dropoff_longitude']),
    );

    final finalFare = await cubit.completeRide();
    if (finalFare == null) return;

    if (mounted) {
      context.pushNamed(
        TripRoutes.fareSummary,
        extra: {
          'pickup': trip['pickup_name'] ?? 'Pickup',
          'dropoff': trip['dropoff_name'] ?? 'Dropoff',
          'distance': distance,
          'fare': finalFare,
          'duration': '${duration.toStringAsFixed(0)} min',
        },
      );
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
          _startPolling();
        } else {
          _availabilityCtrl.reverse();
          _stopPolling();
        }
      },
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          final showFeed =
              state.isOnline &&
              (_activeBids.isNotEmpty || _activeTrips.isNotEmpty);
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSectionLabel('Incoming request'),
                                const Text(
                                  '0:12',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.accent,
                                  ),
                                ),
                              ],
                            ),
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
                                      ? Colors.white
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
                                      ? Colors.white.withValues(alpha: 0.8)
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
            Colors.white.withValues(alpha: 0.28),
            animationProgress,
          )!
        : AppTheme.borderSide;
    final thumbColor = isOnline
        ? Color.lerp(AppTheme.primaryColor, Colors.white, animationProgress)!
        : AppTheme.primaryColor.withValues(alpha: 0.4);

    return SizedBox(
      width: 56,
      height: 32,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Switch(
          value: isOnline,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          activeThumbColor: thumbColor,
          activeTrackColor: Colors.transparent,
          inactiveThumbColor: thumbColor,
          inactiveTrackColor: Colors.transparent,
          onChanged: (value) => _toggleOnline(context, value),
        ),
      ),
    );
  }

  Widget _buildStatsRow(DashboardState state) {
    return DriverDashboardStatsRowWidget(
      isLoadingStats: state.isLoadingStats,
      todayEarnings: state.todayEarnings,
      todayTrips: state.todayTrips,
      hoursOnline: state.hoursOnline,
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
    String statusLabel = 'En Route';
    Color statusColor = AppTheme.inProgress;
    if (status == 'arrived') {
      statusLabel = 'Waiting Passenger';
      statusColor = AppTheme.secondaryColor;
    } else if (status == 'in_transit') {
      statusLabel = 'In Transit';
      statusColor = AppTheme.complete;
    }
    final hasCurrentTransitRide = _activeTrips.any(
      (activeTrip) => activeTrip['status'] == 'in_transit',
    );
    final isQueued = hasCurrentTransitRide && status != 'in_transit';

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
            color: Colors.black.withValues(alpha: 0.05),
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
                trip['passenger_name'] ?? 'Passenger',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                LucideIcons.map_pin,
                size: 14,
                color: AppTheme.primaryColor.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'To: ${trip['dropoff_name']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.primaryColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
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
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                      onPressed: () => _completeTripFromDashboard(trip),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.complete,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
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
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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

  Widget _buildPoolBidCard(Map<String, dynamic> bid) {
    final pickup = bid['pickup_name']?.toString() ?? '—';
    final dropoff = bid['dropoff_name']?.toString() ?? '—';
    final fare = driverFareInPesos(bid);
    final distance = _distanceInKm(bid);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderSide),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                LucideIcons.map_pin,
                color: AppTheme.secondaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pickup,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                LucideIcons.navigation,
                color: AppTheme.secondaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Drop-off',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dropoff,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.borderSide),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                distance == null
                    ? 'Distance unavailable'
                    : '${distance.toStringAsFixed(1)} km away',
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
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _activeBids.removeWhere((b) => b['id'] == bid['id']);
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppTheme.borderSide),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
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
                  onPressed: fare == null ? null : () => _acceptBid(bid),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

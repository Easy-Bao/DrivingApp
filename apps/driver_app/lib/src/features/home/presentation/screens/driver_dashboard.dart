import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:driver_app/src/features/home/presentation/bloc/dashboard_cubit.dart';
import 'package:driver_app/src/features/home/presentation/bloc/dashboard_state.dart';
import 'package:driver_app/src/features/trip/trip_routes.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/live_map/live_map_event.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver_services/driver_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  Timer? _rideTriggerTimer;
  StreamSubscription<Position>? _locationSubscription;
  List<Map<String, dynamic>> _activeBids = [];
  List<Map<String, dynamic>> _activeTrips = [];
  LiveMapBloc? _liveMapBloc;

  @override
  void initState() {
    super.initState();
    _liveMapBloc = Modular.get<LiveMapBloc>();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final s = BlocProvider.of<DashboardCubit>(context).state;
        if (s.isOnline) {
          _startPolling();
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rideTriggerTimer?.cancel();
    _locationSubscription?.cancel();
    _liveMapBloc?.close();
    super.dispose();
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
    _rideTriggerTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) async {
      if (!mounted) return;
      final s = BlocProvider.of<DashboardCubit>(context).state;
      if (!s.isOnline) {
        timer.cancel();
        return;
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        final driverId = prefs.getString('driver_id') ?? '';
        if (driverId.isEmpty) return;

        final list = await Modular.get<TripRemoteDataSource>().fetchTripHistory(driverId);
        List<Map<String, dynamic>> trips = list
            .where((r) {
              final status = r['status'] as String?;
              return status == 'accepted' ||
                  status == 'arrived' ||
                  status == 'in_transit';
            })
            .map((r) => r as Map<String, dynamic>)
            .toList();

        final bidsList = await Modular.get<BiddingRemoteDataSource>().fetchActiveBids(
          driverId,
        );
        final List<Map<String, dynamic>> bids = bidsList
            .map((b) => b as Map<String, dynamic>)
            .toList();

        if (mounted) {
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

  void _toggleOnline(BuildContext context, bool currentOnline) {
    final pos = LocationService.lastPosition;
    if (pos != null) {
      BlocProvider.of<DashboardCubit>(
        context,
      ).toggleOnline(lat: pos.latitude, lng: pos.longitude);
    } else {
      unawaited(
        LocationService.getCurrentPosition().then((p) {
          if (p != null && context.mounted) {
            BlocProvider.of<DashboardCubit>(
              context,
            ).toggleOnline(lat: p.latitude, lng: p.longitude);
          }
        }),
      );
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

    final prefs = await SharedPreferences.getInstance();
    final driverId = prefs.getString('driver_id') ?? '';
    final driverName = prefs.getString('driver_name') ?? 'Driver';
    final vehicleType = prefs.getString('vehicle_type') ?? 'Bao Bao';
    final plateNumber = prefs.getString('plate_number') ?? 'ABC 1234';

    final success = await Modular.get<BiddingRemoteDataSource>().placeBid(
      sessionId: bid['id'],
      driverId: driverId,
      driverName: driverName,
      plateNumber: plateNumber,
      vehicleType: vehicleType,
      proposedFare: SafeParse.toDouble(bid['offered_fare'] ?? bid['fare']),
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
    final status = trip['status'] as String?;
    String routeName = TripRoutes.enRoutePickup;
    if (status == 'arrived') {
      routeName = TripRoutes.waitingPassenger;
    } else if (status == 'in_transit') {
      routeName = TripRoutes.inTransit;
    }

    BlocProvider.of<RideFlowCubit>(context).resumeRide(
      rideId: trip['id'],
      status: trip['status'] ?? 'accepted',
      passengerName: trip['passenger_name'] ?? 'Passenger',
      pickupLat: SafeParse.toDouble(trip['pickup_latitude']),
      pickupLng: SafeParse.toDouble(trip['pickup_longitude']),
      destLat: SafeParse.toDouble(trip['dropoff_latitude']),
      destLng: SafeParse.toDouble(trip['dropoff_longitude']),
    );

    context.pushNamed(
      routeName,
      extra: {
        'pickup': trip['pickup_name'] ?? 'Pickup',
        'dropoff': trip['dropoff_name'] ?? 'Dropoff',
        'distance': 3.2,
        'fare': SafeParse.toDouble(trip['fare']),
        'duration': '8 min',
      },
    );
  }

  Future<void> _completeTripFromDashboard(Map<String, dynamic> trip) async {
    final rideId = trip['id'] as String?;
    if (rideId == null) return;

    final cubit = BlocProvider.of<RideFlowCubit>(context);
    cubit.resumeRide(
      rideId: rideId,
      status: trip['status'] ?? 'accepted',
      passengerName: trip['passenger_name'] ?? 'Passenger',
      pickupLat: SafeParse.toDouble(trip['pickup_latitude']),
      pickupLng: SafeParse.toDouble(trip['pickup_longitude']),
      destLat: SafeParse.toDouble(trip['dropoff_latitude']),
      destLng: SafeParse.toDouble(trip['dropoff_longitude']),
    );

    await cubit.endRide(distanceKm: 3.2, durationMinutes: 10);

    if (mounted) {
      context.pushNamed(
        TripRoutes.completeTrip,
        extra: {
          'pickup': trip['pickup_name'] ?? 'Pickup',
          'dropoff': trip['dropoff_name'] ?? 'Dropoff',
          'distance': 3.2,
          'fare': SafeParse.toDouble(trip['fare']),
          'duration': '10 min',
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DashboardCubit, DashboardState>(
      listenWhen: (previous, current) => previous.isOnline != current.isOnline,
      listener: (context, state) {
        if (state.isOnline) {
          _startPolling();
        } else {
          _stopPolling();
        }
      },
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          final showFeed =
              state.isOnline &&
              (_activeBids.isNotEmpty || _activeTrips.isNotEmpty);
          return Scaffold(
            backgroundColor: AppTheme.surface,
            body: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(state),
                  const SizedBox(height: 20),
                  _buildStatsRow(state),
                  const SizedBox(height: 16),
                  if (showFeed)
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          if (_activeTrips.isNotEmpty) ...[
                            _buildSectionLabel(
                              'Your active rides (${_activeTrips.length}/5)',
                            ),
                            const SizedBox(height: 10),
                            ..._activeTrips.map(_buildActiveTripCard),
                            const SizedBox(height: 24),
                          ],
                          if (_activeBids.isNotEmpty) ...[
                            _buildSectionLabel(
                              'Available Requests',
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
                  _buildToggleButton(context, state),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(DashboardState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good ${_greeting()},',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryColor.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Driver',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          _StatusPill(
            isOnline: state.isOnline,
            isLoading: state.isLoadingHeatmap,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(DashboardState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
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
        child: state.isLoadingStats
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : Row(
                children: [
                  _StatCell(
                    value: '₱${state.todayEarnings.toStringAsFixed(0)}',
                    label: 'Earnings',
                    icon: LucideIcons.banknote,
                  ),
                  _Divider(),
                  _StatCell(
                    value: '${state.todayTrips}',
                    label: 'Trips',
                    icon: LucideIcons.route,
                  ),
                  _Divider(),
                  _StatCell(
                    value: '${state.hoursOnline.toStringAsFixed(1)}h',
                    label: 'Online',
                    icon: LucideIcons.clock,
                  ),
                ],
              ),
      ),
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
              Icon(LucideIcons.radar, size: 34, color: AppTheme.complete),
              const SizedBox(height: 10),
              Text(
                'Looking for rides...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.complete,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Icon(
          LucideIcons.moon,
          size: 34,
          color: AppTheme.primaryColor.withValues(alpha: 0.25),
        ),
        const SizedBox(height: 10),
        Text(
          "You're offline",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Go online to start receiving rides',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(BuildContext context, DashboardState state) {
    final isOnline = state.isOnline;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => _toggleOnline(context, isOnline),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: isOnline ? AppTheme.cancel : AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: (isOnline ? AppTheme.cancel : AppTheme.primaryColor)
                    .withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              isOnline ? 'Go Offline' : 'Go Online',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTripCard(Map<String, dynamic> trip) {
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSide),
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
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor == AppTheme.secondaryColor
                        ? AppTheme.primaryColor
                        : statusColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '₱${SafeParse.toDouble(trip['fare']).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                LucideIcons.user,
                size: 14,
                color: AppTheme.tertiaryColor,
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
              const Icon(
                LucideIcons.map_pin,
                size: 14,
                color: AppTheme.tertiaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'To: ${trip['dropoff_name']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor.withValues(alpha: 0.6),
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
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPoolBidCard(Map<String, dynamic> bid) {
    final rating = bid['passenger_rating'] ?? '4.8';
    final isPriority = bid['ride_type'] == 'Bao Premium';

    final Position? driverPos = LocationService.lastPosition;
    final double passengerLat = SafeParse.toDouble(
      bid['pickup_latitude'] ?? 0.0,
    );
    final double passengerLng = SafeParse.toDouble(
      bid['pickup_longitude'] ?? 0.0,
    );

    double distanceToPassenger = SafeParse.toDouble(
      bid['distance_km'] ?? bid['distance'] ?? 1.5,
    );
    if (driverPos != null && passengerLat != 0.0 && passengerLng != 0.0) {
      distanceToPassenger = MapNativeServiceImpl.calculateHaversine(
        driverPos.latitude,
        driverPos.longitude,
        passengerLat,
        passengerLng,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPriority ? AppTheme.secondaryColor : AppTheme.borderSide,
          width: isPriority ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                bid['passenger_name'] ?? 'Passenger',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.complete.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '★ $rating',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.complete,
                  ),
                ),
              ),
              if (isPriority) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cancel.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PRIORITY',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.cancel,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '₱${SafeParse.toDouble(bid['offered_fare'] ?? bid['fare']).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                LucideIcons.navigation,
                size: 14,
                color: AppTheme.tertiaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                '${distanceToPassenger.toStringAsFixed(1)} km away',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryColor.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                LucideIcons.map_pin,
                size: 14,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'From: ${bid['pickup_name'] ?? 'Current Location'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.primaryColor.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                LucideIcons.map_pin,
                size: 14,
                color: AppTheme.tertiaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'To: ${bid['dropoff_name']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.primaryColor.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => _acceptBid(bid),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPriority
                          ? AppTheme.cancel
                          : AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isPriority ? 'Accept Priority' : 'Accept Ride',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
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
          color: AppTheme.primaryColor.withValues(alpha: 0.38),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isOnline, required this.isLoading});

  final bool isOnline;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isOnline
            ? AppTheme.complete.withValues(alpha: 0.1)
            : AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOnline && isLoading)
            SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation(AppTheme.complete),
              ),
            )
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isOnline ? AppTheme.complete : AppTheme.cancel,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 8),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isOnline ? AppTheme.complete : AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppTheme.tertiaryColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppTheme.borderSide);
  }
}

import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:driver_app/src/Core/Network/DriverOperationsClient.dart';
import 'package:driver_app/src/Features/Home/Presentation/Bloc/DashboardCubit.dart';
import 'package:driver_app/src/Features/Home/Presentation/Bloc/DashboardState.dart';
import 'package:driver_app/src/Features/Home/Presentation/Widgets/Driver_dashboard/DriverDashboardStatsRowWidget.dart';
import 'package:driver_app/src/Features/Profile/ProfileRoutes.dart';
import 'package:driver_app/src/Features/Trip/Presentation/Bloc/LiveMap/LiveMapBloc.dart';
import 'package:driver_app/src/Features/Trip/Presentation/Bloc/LiveMap/LiveMapEvent.dart';
import 'package:driver_app/src/Features/Trip/Presentation/Bloc/RideFlow/RideFlowCubit.dart';
import 'package:driver_app/src/Features/Trip/TripRoutes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:geolocator/geolocator.dart';
import 'package:driver_app/src/Core/Services/SecureSessionService.dart';
import 'package:driver_app/src/Features/Trip/Data/DataSources/BiddingRemoteDataSource.dart';
import 'package:location_service/location_service.dart';
import 'package:go_router_modular/go_router_modular.dart';
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

    try {
      final driverId =
          await Modular.get<SecureSessionService>().readDriverId() ?? '';
      final success = await Modular.get<BiddingRemoteDataSource>().placeBid(
        sessionId: bid['id'],
        driverId: driverId,
        offerPrice: SafeParse.toDouble(bid['offered_fare'] ?? bid['fare']),
        proposedFare: SafeParse.toDouble(bid['offered_fare'] ?? bid['fare']),
      );

      if (mounted) {
        if (success) {
          CustomToast.show(
            context,
            'Offer submitted! Waiting for passenger...',
          );
        } else {
          CustomToast.show(context, 'Failed to submit offer.', isError: true);
        }
      }
    } catch (error) {
      if (mounted) {
        CustomToast.show(context, driverOperationMessage(error), isError: true);
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
      listenWhen: (previous, current) =>
          previous.isOnline != current.isOnline ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.isOnline) {
          _startPolling();
        } else {
          _stopPolling();
        }
        if (state.errorMessage != null) {
          CustomToast.show(context, state.errorMessage!, isError: true);
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
                  const SizedBox(height: 16),
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
                            ..._activeTrips.map(_buildActiveTripCard),
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
                                    color: AppTheme.secondaryColor,
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

  Widget _buildTopBar(DashboardState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BaoRide',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Driver',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () async {
              await context.pushNamed(ProfileRoutes.account);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.user,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineCardBanner(BuildContext context, DashboardState state) {
    final isOnline = state.isOnline;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isOnline ? AppTheme.secondaryColor : AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(20),
          border: isOnline ? null : Border.all(color: AppTheme.borderSide),
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
                    color: isOnline ? Colors.white : AppTheme.primaryColor,
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
                        : AppTheme.primaryColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            Transform.scale(
              scale: 1.1,
              child: Switch(
                value: isOnline,
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.white.withValues(alpha: 0.3),
                inactiveThumbColor: AppTheme.primaryColor.withValues(
                  alpha: 0.4,
                ),
                inactiveTrackColor: AppTheme.borderSide,
                onChanged: (_) => _toggleOnline(context, isOnline),
              ),
            ),
          ],
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
                  color: AppTheme.complete.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.radar,
                    size: 32,
                    color: AppTheme.complete,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Looking for rides...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.complete,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final blocked = state.blockingCode != null;
    final blockedMessage = blocked
        ? driverOperationMessage(
            DriverOperationException(
              code: state.blockingCode,
              message: state.blockingMessage ?? state.blockingCode!,
            ),
          )
        : 'Go online to start receiving rides.';

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
              blocked ? LucideIcons.shield_alert : LucideIcons.moon,
              size: 32,
              color: AppTheme.primaryColor.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          blocked ? 'Account not ready' : "You're offline",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          blockedMessage,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.primaryColor.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
                '₱${SafeParse.toDouble(trip['fare']).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 17,
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
    final pickup = bid['pickup_name'] ?? 'Guiwan, Zamboanga City';
    final dropoff = bid['dropoff_name'] ?? 'KCC Mall, Zamboanga City';
    final fare = SafeParse.toDouble(bid['offered_fare'] ?? bid['fare']);
    final distance = (bid['distance'] as num?)?.toDouble() ?? 2.4;

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
                '${distance.toStringAsFixed(1)} km away · ~8 min',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                ),
              ),
              Text(
                '₱${fare > 0 ? fare.toStringAsFixed(0) : '145'}',
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
                  onPressed: () => _acceptBid(bid),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
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

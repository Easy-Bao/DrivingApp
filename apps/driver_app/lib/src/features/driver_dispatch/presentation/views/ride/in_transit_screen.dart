import 'dart:async';

import 'package:driver_app/src/core/di/service_locator.dart';
import 'package:driver_app/src/core/services/driver_api_service.dart';
import 'package:driver_app/src/core/themes/app_themes.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/ride/ride_flow_cubit.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/ride/ride_flow_state.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/live_map/live_map_bloc.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/live_map/live_map_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InTransitScreen extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final String duration;
  final double distance;
  final double fare;

  const InTransitScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.distance,
    required this.fare,
    required this.duration,
  });

  @override
  State<InTransitScreen> createState() => _InTransitScreenState();
}

class _InTransitScreenState extends State<InTransitScreen> {
  bool _isLoading = true;
  double _destLat = 8.5862;
  double _destLng = 123.3392;
  Timer? _trackingTimer;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  void _startTracking(BuildContext context) {
    final mapBloc = BlocProvider.of<LiveMapBloc>(context);
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) return;
      try {
        final pos = await LocationService.getCurrentPosition() ?? LocationService.lastPosition;
        if (pos != null) {
          final prefs = await SharedPreferences.getInstance();
          final driverId = prefs.getString('driver_id') ?? '';
          if (driverId.isNotEmpty) {
            await DriverApiService.updateLocation(
              driverId: driverId,
              lat: pos.latitude,
              lng: pos.longitude,
            );
          }
          if (mounted) {
            mapBloc.add(UpdateLocationsAndDrawRouteEvent(
              driverLat: pos.latitude,
              driverLng: pos.longitude,
              passengerLat: _destLat,
              passengerLng: _destLng,
            ));
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _loadRoute() async {
    final pos = await LocationService.getCurrentPosition() ?? LocationService.lastPosition;
    if (!mounted) return;
    if (pos == null) return;
    final dLat = pos.latitude;
    final dLng = pos.longitude;

    final rideState = BlocProvider.of<RideFlowCubit>(context).state;
    if (rideState is RideFlowInTransit) {
      _destLat = rideState.destLat;
      _destLng = rideState.destLng;
    } else {
      final places = await MapProvider.searchPlaces(widget.dropoff);
      if (places.isNotEmpty) {
        _destLat = places.first.latitude;
        _destLng = places.first.longitude;
      } else {
        _destLat = dLat;
        _destLng = dLng;
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    _startTracking(context);
  }

  void _triggerDrawRoute(BuildContext context, double dLat, double dLng) {
    BlocProvider.of<LiveMapBloc>(context).add(UpdateLocationsAndDrawRouteEvent(
      driverLat: dLat,
      driverLng: dLng,
      passengerLat: _destLat,
      passengerLng: _destLng,
    ));
  }

  void _onMapCreated(AppMapController controller, BuildContext context) {
    final pos = LocationService.lastPosition;
    final defaultLat = pos?.latitude ?? _destLat;
    final defaultLng = pos?.longitude ?? _destLng;

    BlocProvider.of<LiveMapBloc>(context).add(InitializeMapEvent(
      controller: controller,
      defaultLat: defaultLat,
      defaultLng: defaultLng,
    ));

    if (!_isLoading) {
      _triggerDrawRoute(context, defaultLat, defaultLng);
    }
  }

  Future<void> _completeTrip(BuildContext context) async {
    await BlocProvider.of<RideFlowCubit>(context).endRide(
      distanceKm: widget.distance,
      durationMinutes: 10,
    );
    if (context.mounted) {
      context.pushReplacementNamed(
        'CompleteTripDriver',
        extra: {
          'pickup': widget.pickup,
          'dropoff': widget.dropoff,
          'distance': widget.distance,
          'fare': widget.fare,
          'duration': widget.duration,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LiveMapBloc>(
      create: (_) => getIt<LiveMapBloc>(),
      child: Builder(
        builder: (context) {
          final rideCubitState = BlocProvider.of<RideFlowCubit>(context).state;
          final defaultLat = LocationService.lastPosition?.latitude ??
              (rideCubitState is RideFlowInTransit ? rideCubitState.destLat : 0.0);
          final defaultLng = LocationService.lastPosition?.longitude ??
              (rideCubitState is RideFlowInTransit ? rideCubitState.destLng : 0.0);

          return Scaffold(
            backgroundColor: AppTheme.surface,
            body: Stack(
              children: [
                Positioned.fill(
                  child: SizedBox.expand(
                    child: MapProvider.buildMapView(
                      latitude: defaultLat,
                      longitude: defaultLng,
                      zoom: 15.0,
                      onMapCreated: (c) => _onMapCreated(c, context),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: AppTheme.neutralColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.borderSide),
                            ),
                            child: const Icon(
                              LucideIcons.arrow_left,
                              size: 18,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        _buildStatusBadge(),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDestinationCard(),
                        const SizedBox(height: 16),
                        _buildMetaRow(),
                        const SizedBox(height: 16),
                        _buildPassengerRow(context),
                        const SizedBox(height: 24),
                        _buildCompleteButton(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.route, size: 13, color: Colors.white),
          SizedBox(width: 6),
          Text(
            'IN TRANSIT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HEADING TO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 18,
                color: AppTheme.tertiaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.dropoff,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow() {
    return Row(
      children: [
        _chip(LucideIcons.map_pin, '${widget.distance.toStringAsFixed(1)} km'),
        const SizedBox(width: 10),
        _chip(LucideIcons.clock, widget.duration),
        const SizedBox(width: 10),
        _chip(LucideIcons.banknote, '₱${widget.fare.toStringAsFixed(0)}'),
      ],
    );
  }

  Widget _chip(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderSide),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: AppTheme.tertiaryColor),
            const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerRow(BuildContext context) {
    final state = BlocProvider.of<RideFlowCubit>(context).state;
    final passengerName = state is RideFlowInTransit ? state.passengerName : 'Passenger';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.user,
              color: AppTheme.primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passengerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Text(
                  'Aboard',
                  style: TextStyle(fontSize: 12, color: AppTheme.tertiaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _completeTrip(context),
      child: Container(
        width: double.infinity,
        height: 68,
        decoration: BoxDecoration(
          color: AppTheme.complete,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: AppTheme.complete.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'COMPLETE TRIP',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

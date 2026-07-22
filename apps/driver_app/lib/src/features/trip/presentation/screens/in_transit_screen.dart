import 'dart:async';

import 'package:driver_app/src/features/trip/trip_routes.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/live_map/live_map_event.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver_app/src/features/trip/presentation/widgets/in_transit/in_transit_complete_button_widget.dart';
import 'package:driver_app/src/features/trip/presentation/widgets/in_transit/in_transit_destination_card_widget.dart';
import 'package:driver_app/src/features/trip/presentation/widgets/in_transit/in_transit_meta_row_widget.dart';
import 'package:driver_app/src/features/trip/presentation/widgets/in_transit/in_transit_passenger_card_widget.dart';
import 'package:driver_app/src/features/trip/presentation/widgets/in_transit/in_transit_status_badge_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/location_service.dart';
import 'package:shared_ui/shared_ui.dart';

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
  double _destLat = 0.0;
  double _destLng = 0.0;
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
        final pos =
            await LocationService.getCurrentPosition() ??
            LocationService.lastPosition;
        if (pos != null) {
          if (mounted) {
            mapBloc.add(
              DispatchTelemetryLocationEvent(
                lat: pos.latitude,
                lng: pos.longitude,
              ),
            );
          }
          if (mounted) {
            mapBloc.add(
              UpdateLocationsAndDrawRouteEvent(
                driverLat: pos.latitude,
                driverLng: pos.longitude,
                passengerLat: _destLat,
                passengerLng: _destLng,
              ),
            );
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _loadRoute() async {
    final pos =
        await LocationService.getCurrentPosition() ??
        LocationService.lastPosition;
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
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _triggerDrawRoute(context, dLat, dLng);
      _startTracking(context);
    }
  }

  void _triggerDrawRoute(BuildContext context, double dLat, double dLng) {
    BlocProvider.of<LiveMapBloc>(context).add(
      UpdateLocationsAndDrawRouteEvent(
        driverLat: dLat,
        driverLng: dLng,
        passengerLat: _destLat,
        passengerLng: _destLng,
      ),
    );
  }

  void _onMapCreated(AppMapController controller, BuildContext context) {
    final pos = LocationService.lastPosition;
    final defaultLat = pos?.latitude ?? _destLat;
    final defaultLng = pos?.longitude ?? _destLng;

    BlocProvider.of<LiveMapBloc>(context).add(
      InitializeMapEvent(
        controller: controller,
        defaultLat: defaultLat,
        defaultLng: defaultLng,
      ),
    );

    if (!_isLoading) {
      _triggerDrawRoute(context, defaultLat, defaultLng);
    }
  }

  Future<void> _completeTrip(BuildContext context) async {
    await BlocProvider.of<RideFlowCubit>(
      context,
    ).endRide(distanceKm: widget.distance, durationMinutes: 10);
    if (context.mounted) {
      context.pushReplacementNamed(
        TripRoutes.completeTrip,
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
      create: (_) => Modular.get<LiveMapBloc>(),
      child: Builder(
        builder: (context) {
          final rideCubitState = BlocProvider.of<RideFlowCubit>(context).state;
          final defaultLat =
              LocationService.lastPosition?.latitude ??
              (rideCubitState is RideFlowInTransit
                  ? rideCubitState.destLat
                  : 0.0);
          final defaultLng =
              LocationService.lastPosition?.longitude ??
              (rideCubitState is RideFlowInTransit
                  ? rideCubitState.destLng
                  : 0.0);

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
                        const InTransitStatusBadgeWidget(),
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
                        InTransitDestinationCardWidget(
                          dropoffAddress: widget.dropoff,
                        ),
                        const SizedBox(height: 16),
                        InTransitMetaRowWidget(
                          distanceKm: widget.distance,
                          durationText: widget.duration,
                          fareAmount: widget.fare,
                        ),
                        const SizedBox(height: 16),
                        const InTransitPassengerCardWidget(),
                        const SizedBox(height: 24),
                        InTransitCompleteButtonWidget(
                          onCompleteTripPressed: () => _completeTrip(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

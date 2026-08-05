import 'package:driver_app/src/core/location/location.dart';
import 'package:driver_app/src/core/theme/app_theme.dart';

import 'dart:async';

import 'package:driver_app/src/features/trip/trip_routes.dart';
import 'package:driver_app/src/features/trip/bloc/live_map/live_map_bloc.dart';
import 'package:driver_app/src/features/trip/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver_app/src/features/trip/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver_app/src/features/trip/view/widgets/in_transit/in_transit_complete_button_widget.dart';
import 'package:driver_app/src/features/trip/view/widgets/in_transit/in_transit_destination_card_widget.dart';
import 'package:driver_app/src/features/trip/view/widgets/in_transit/in_transit_meta_row_widget.dart';
import 'package:driver_app/src/features/trip/view/widgets/in_transit/in_transit_passenger_card_widget.dart';
import 'package:driver_app/src/features/trip/view/widgets/in_transit/in_transit_status_badge_widget.dart';
import 'package:driver_app/src/features/trip/view/widgets/trip_map_current_location_button.dart';
import 'package:driver_app/src/features/trip/data/datasources/telemetry_remote_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_ui/shared_ui.dart';

class InTransitPage extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final String duration;
  final double distance;
  final double fare;

  const InTransitPage({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.distance,
    required this.fare,
    required this.duration,
  });

  @override
  State<InTransitPage> createState() => _InTransitPageState();
}

class _InTransitPageState extends State<InTransitPage> {
  bool _isLoading = true;
  bool _isCompletingTrip = false;
  double? _destLat;
  double? _destLng;
  double? _passengerLat;
  double? _passengerLng;
  AppMapController? _mapController;
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
        final rideId = BlocProvider.of<RideFlowCubit>(context).activeRideId;
        if (rideId != null && rideId.isNotEmpty) {
          final location = await Modular.get<TelemetryRemoteDataSource>()
              .fetchPassengerLocation(rideId);
          if (location['lat'] != null && location['lng'] != null) {
            _passengerLat = (location['lat'] as num).toDouble();
            _passengerLng = (location['lng'] as num).toDouble();
          }
        }
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
                passengerLat: _passengerLat,
                passengerLng: _passengerLng,
                routeTargetLat: _destLat,
                routeTargetLng: _destLng,
              ),
            );
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _loadRoute() async {
    final rideCubit = BlocProvider.of<RideFlowCubit>(context);
    final pos =
        await LocationService.getCurrentPosition() ??
        LocationService.lastPosition;
    if (!mounted) return;
    if (pos == null) return;
    final dLat = pos.latitude;
    final dLng = pos.longitude;

    final rideState = rideCubit.state;
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
    if (rideState is RideFlowInTransit) {
      _passengerLat = rideState.passengerLat;
      _passengerLng = rideState.passengerLng;
    }

    final rideId = rideCubit.activeRideId;
    if (_passengerLat == null && rideId != null && rideId.isNotEmpty) {
      try {
        final location = await Modular.get<TelemetryRemoteDataSource>()
            .fetchPassengerLocation(rideId);
        if (location['lat'] is num && location['lng'] is num) {
          _passengerLat = (location['lat'] as num).toDouble();
          _passengerLng = (location['lng'] as num).toDouble();
        }
      } catch (_) {}
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
    final destinationLat = _destLat;
    final destinationLng = _destLng;
    if (destinationLat == null || destinationLng == null) return;
    BlocProvider.of<LiveMapBloc>(context).add(
      UpdateLocationsAndDrawRouteEvent(
        driverLat: dLat,
        driverLng: dLng,
        passengerLat: _passengerLat,
        passengerLng: _passengerLng,
        routeTargetLat: destinationLat,
        routeTargetLng: destinationLng,
      ),
    );
  }

  void _onMapCreated(AppMapController controller, BuildContext context) {
    _mapController = controller;
    final pos = LocationService.lastPosition;
    final defaultLat = pos?.latitude ?? _destLat;
    final defaultLng = pos?.longitude ?? _destLng;
    if (defaultLat == null || defaultLng == null) return;

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

  Future<void> _recenterMap() async {
    final controller = _mapController;
    final position =
        await LocationService.getCurrentPosition() ??
        LocationService.lastPosition;
    if (controller == null || position == null) return;
    await MapProvider.moveCamera(
      controller,
      position.latitude,
      position.longitude,
      zoom: 16,
    );
  }

  Future<void> _completeTrip(BuildContext context) async {
    if (_isCompletingTrip) return;
    setState(() => _isCompletingTrip = true);
    try {
      final finalFare = await BlocProvider.of<RideFlowCubit>(
        context,
      ).completeRide();
      if (finalFare == null) {
        if (mounted) {
          CustomToast.show(
            this.context,
            'Unable to complete the trip. Please try again.',
            isError: true,
          );
        }
        return;
      }
      if (!mounted) return;
      this.context.pushReplacementNamed(
        TripRoutes.fareSummary,
        extra: {
          'pickup': widget.pickup,
          'dropoff': widget.dropoff,
          'distance': widget.distance,
          'fare': finalFare,
          'duration': widget.duration,
        },
      );
    } finally {
      if (mounted) setState(() => _isCompletingTrip = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LiveMapBloc>.value(
      value: Modular.get<LiveMapBloc>(),
      child: Builder(
        builder: (context) {
          final rideCubitState = BlocProvider.of<RideFlowCubit>(context).state;
          final position = LocationService.lastPosition;
          final transitState = rideCubitState is RideFlowInTransit
              ? rideCubitState
              : null;
          final defaultLat = position?.latitude ?? transitState?.destLat;
          final defaultLng = position?.longitude ?? transitState?.destLng;
          if (defaultLat == null || defaultLng == null) {
            return const Scaffold(
              body: Center(child: Text('Destination location is unavailable.')),
            );
          }

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
                Positioned(
                  top: 112,
                  right: 20,
                  child: TripMapCurrentLocationButton(
                    onPressed: _mapController == null ? null : _recenterMap,
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
                          isCompletingTrip: _isCompletingTrip,
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

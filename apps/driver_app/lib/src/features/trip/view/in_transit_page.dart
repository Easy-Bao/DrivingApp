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
  Timer? _trackingTimer;
  late final LiveMapBloc _liveMapBloc;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _liveMapBloc = Modular.get<LiveMapBloc>();
    unawaited(_loadRoute());
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    unawaited(_liveMapBloc.close());
    super.dispose();
  }

  void _startTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!mounted || _isTracking) return;
      _isTracking = true;

      try {
        final rideId = BlocProvider.of<RideFlowCubit>(context).activeRideId;
        if (rideId != null && rideId.isNotEmpty) {
          final location = await Modular.get<TelemetryRemoteDataSource>()
              .fetchPassengerLocation(rideId);
          if (location['lat'] is num && location['lng'] is num) {
            _passengerLat = (location['lat'] as num).toDouble();
            _passengerLng = (location['lng'] as num).toDouble();
          }
        }
        final pos =
            LocationService.lastPosition ??
            await LocationService.getCurrentPosition();
        if (pos != null) {
          if (mounted) {
            _liveMapBloc.add(
              DispatchTelemetryLocationEvent(
                lat: pos.latitude,
                lng: pos.longitude,
              ),
            );
          }
          if (mounted) {
            _liveMapBloc.add(
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
      } catch (_) {
        // The next bounded refresh can recover from a transient location or
        // telemetry failure without breaking the active trip screen.
      } finally {
        _isTracking = false;
      }
    });
  }

  Future<void> _loadRoute() async {
    final rideCubit = BlocProvider.of<RideFlowCubit>(context);
    final pos =
        LocationService.lastPosition ??
        await LocationService.getCurrentPosition();
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
      _triggerDrawRoute(dLat, dLng);
      _startTracking();
    }
  }

  void _triggerDrawRoute(double dLat, double dLng) {
    final destinationLat = _destLat;
    final destinationLng = _destLng;
    if (destinationLat == null || destinationLng == null) return;
    _liveMapBloc.add(
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

  void _onMapCreated(AppMapController controller) {
    final pos = LocationService.lastPosition;
    final defaultLat = pos?.latitude ?? _destLat;
    final defaultLng = pos?.longitude ?? _destLng;
    if (defaultLat == null || defaultLng == null) return;

    _liveMapBloc.add(
      InitializeMapEvent(
        controller: controller,
        defaultLat: defaultLat,
        defaultLng: defaultLng,
      ),
    );

    if (!_isLoading) {
      _triggerDrawRoute(defaultLat, defaultLng);
    }
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
      value: _liveMapBloc,
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
                      onMapCreated: _onMapCreated,
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Back',
                          onPressed: () => context.pop(),
                          icon: const Icon(
                            LucideIcons.arrow_left,
                            size: 20,
                            color: AppTheme.primaryColor,
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
                  child: SafeArea(
                    top: false,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.12,
                            ),
                            blurRadius: 22,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.borderSide,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          const SizedBox(height: 10),
                          InTransitDestinationCardWidget(
                            dropoffAddress: widget.dropoff,
                          ),
                          const SizedBox(height: 8),
                          InTransitMetaRowWidget(
                            distanceKm: widget.distance,
                            durationText: widget.duration,
                            fareAmount: widget.fare,
                          ),
                          const SizedBox(height: 8),
                          const InTransitPassengerCardWidget(),
                          const SizedBox(height: 12),
                          InTransitCompleteButtonWidget(
                            isCompletingTrip: _isCompletingTrip,
                            onCompleteTripPressed: () => _completeTrip(context),
                          ),
                        ],
                      ),
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

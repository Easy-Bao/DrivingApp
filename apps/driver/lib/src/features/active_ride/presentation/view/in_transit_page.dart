import 'package:maps/maps.dart';

import 'dart:async';

import 'package:driver/src/features/active_ride/active_ride_routes.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver/src/features/active_ride/domain/repositories/driver_ride_repository.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/in_transit/in_transit_complete_button_widget.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/in_transit/in_transit_passenger_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:foundation/foundation.dart';
import 'package:design_system/design_system.dart';

class const InTransitPage({
  super.key,
  required this.pickup,
  required this.dropoff,
  required this.distance,
  required this.fare,
  required this.duration,
  required this.rideRepository,
  required this.lifecycleCoordinator,
}) extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final String duration;
  final double distance;
  final double fare;
  final DriverRideRepository rideRepository;
  final AppLifecycleCoordinator lifecycleCoordinator;

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
  late final AppLifecyclePeriodicTask _trackingTask;
  late final LiveMapBloc _liveMapBloc;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _liveMapBloc = Modular.get<LiveMapBloc>();
    _trackingTask = AppLifecyclePeriodicTask(
      lifecycleCoordinator: widget.lifecycleCoordinator,
      interval: const Duration(seconds: 4),
      onTick: _refreshTracking,
      runImmediatelyOnResume: true,
    );
    unawaited(_loadRoute());
  }

  @override
  void dispose() {
    unawaited(_trackingTask.dispose());
    unawaited(_liveMapBloc.close());
    super.dispose();
  }

  void _startTracking() {
    _trackingTask.start();
  }

  Future<void> _refreshTracking() async {
    if (!mounted || _isTracking) return;
    _isTracking = true;

    try {
      final rideId = BlocProvider.of<RideFlowCubit>(context).activeRideId;
      if (rideId != null && rideId.isNotEmpty) {
        await _refreshPassengerLocation(rideId);
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
  }

  Future<void> _loadRoute() async {
    try {
      final rideCubit = BlocProvider.of<RideFlowCubit>(context);
      final rideState = rideCubit.state;
      // Resolve the destination before waiting on driver location so a
      // delayed permission response cannot prevent the destination leg from
      // being rendered.
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
          await _refreshPassengerLocation(rideId);
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      final pos =
          LocationService.lastPosition ??
          await LocationService.getCurrentPosition();
      if (!mounted) return;
      if (pos != null) {
        _triggerDrawRoute(pos.latitude, pos.longitude);
      }
      _startTracking();
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Unable to load destination route: $error\n$stackTrace');
    }
  }

  Future<void> _refreshPassengerLocation(String rideId) async {
    (await widget.rideRepository.fetchPassengerLocation(rideId))
        .fold((_) {}, (location) {
          if (location == null) return;
          _passengerLat = location.$1;
          _passengerLng = location.$2;
        });
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
        routeColor: context.colorScheme.primary,
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
      final finalFare = await BlocProvider.of<RideFlowCubit>(context)
          .completeRide();
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
        ActiveRideRoutes.fareSummary,
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
          final defaultLat =
              position?.latitude ?? transitState?.destLat ?? _destLat;
          final defaultLng =
              position?.longitude ?? transitState?.destLng ?? _destLng;
          if (defaultLat == null || defaultLng == null) {
            return const Scaffold(
              body: Center(child: Text('Destination location is unavailable.')),
            );
          }

          return Scaffold(
            backgroundColor: context.colorScheme.surface,
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
                    child: _buildTripBackButton(context, () => context.pop()),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: context.colorScheme.onSurface.withValues(
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
                              color: context.colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          const SizedBox(height: 10),
                          CompactRouteTimelineWidget(
                            pickup: widget.pickup,
                            dropoff: widget.dropoff,
                            pickupLabel: 'Pickup',
                            dropoffLabel: 'Drop Off',
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

Widget _buildTripBackButton(BuildContext context, VoidCallback onPressed) {
  return Tooltip(
    message: MaterialLocalizations.of(context).backButtonTooltip,
    child: Material(
      color: context.colorScheme.surface,
      elevation: 2,
      shadowColor: context.colorScheme.onSurface.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Center(
            child: Icon(
              LucideIcons.arrow_left,
              color: context.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    ),
  );
}

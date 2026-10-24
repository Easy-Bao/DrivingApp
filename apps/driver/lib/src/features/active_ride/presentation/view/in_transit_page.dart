import 'package:maps/maps.dart';

import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/active_ride_routes.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/driver_active_ride_header.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/in_transit/in_transit_completion_slider.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/in_transit/in_transit_passenger_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class const InTransitPage({
  super.key,
  required this.pickup,
  required this.dropoff,
  required this.distance,
  required this.fare,
  required this.duration,
  required this.lifecycleCoordinator,
  this.liveMapBloc,
}) extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final String duration;
  final double distance;
  final double fare;
  final AppLifecycleCoordinator lifecycleCoordinator;
  final LiveMapBloc? liveMapBloc;

  @override
  State<InTransitPage> createState() => _InTransitPageState();
}

class _InTransitPageState extends State<InTransitPage> {
  bool _isLoading = true;
  bool _isCompletingTrip = false;
  double _completionSliderProgress = 0;
  double? _destinationLatitude;
  double? _destinationLongitude;
  late final AppLifecyclePeriodicTask _trackingTask;
  late final LiveMapBloc _liveMapBloc;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    unawaited(WakelockPlus.enable());
    _liveMapBloc = widget.liveMapBloc ?? BlocProvider.of<LiveMapBloc>(context);
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
    unawaited(WakelockPlus.disable());
    unawaited(_trackingTask.dispose());
    super.dispose();
  }

  void _startTracking() {
    _trackingTask.start();
  }

  Future<void> _refreshTracking() async {
    if (!mounted || _isTracking) return;
    _isTracking = true;

    try {
      final rideCubit = BlocProvider.of<RideFlowCubit>(context);
      await rideCubit.refreshPassengerLocation();
      final position =
          LocationService.lastPosition ??
          await LocationService.getCurrentPosition();
      if (position != null) {
        if (mounted) {
          _liveMapBloc.add(
            DispatchTelemetryLocationEvent(
              latitude: position.latitude,
              longitude: position.longitude,
            ),
          );
        }
        if (mounted) {
          final rideState = rideCubit.state;
          _liveMapBloc.add(
            UpdateLocationsAndDrawRouteEvent(
              driverLatitude: position.latitude,
              driverLongitude: position.longitude,
              passengerLatitude: rideState.passengerLatitude,
              passengerLongitude: rideState.passengerLongitude,
              routeTargetLatitude: _destinationLatitude,
              routeTargetLongitude: _destinationLongitude,
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
      var rideState = rideCubit.state;
      // Resolve the destination before waiting on driver location so a
      // delayed permission response cannot prevent the destination leg from
      // being rendered.
      final destination = rideState.destinationCoordinates;
      if (destination != null) {
        final (destinationLat, destinationLng) = destination;
        _destinationLatitude = destinationLat;
        _destinationLongitude = destinationLng;
      } else {
        final places = await MapProvider.searchPlaces(widget.dropoff);
        if (places.isNotEmpty) {
          _destinationLatitude = places.first.latitude;
          _destinationLongitude = places.first.longitude;
        }
      }
      final rideId = rideCubit.activeRideId;
      if (rideState.passengerLatitude == null &&
          rideId != null &&
          rideId.isNotEmpty) {
        try {
          await rideCubit.refreshPassengerLocation();
          rideState = rideCubit.state;
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      final position =
          LocationService.lastPosition ??
          await LocationService.getCurrentPosition();
      if (!mounted) return;
      if (position != null) {
        _triggerDrawRoute(position.latitude, position.longitude);
      }
      _startTracking();
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Unable to load destination route: $error\n$stackTrace');
    }
  }

  void _triggerDrawRoute(double driverLatitude, double driverLongitude) {
    final destinationLatitude = _destinationLatitude;
    final destinationLongitude = _destinationLongitude;
    if (destinationLatitude == null || destinationLongitude == null) return;
    final rideState = BlocProvider.of<RideFlowCubit>(context).state;
    _liveMapBloc.add(
      UpdateLocationsAndDrawRouteEvent(
        driverLatitude: driverLatitude,
        driverLongitude: driverLongitude,
        passengerLatitude: rideState.passengerLatitude,
        passengerLongitude: rideState.passengerLongitude,
        routeTargetLatitude: destinationLatitude,
        routeTargetLongitude: destinationLongitude,
      ),
    );
  }

  void _onMapCreated(AppMapController controller) {
    final position = LocationService.lastPosition;
    final defaultLatitude = position?.latitude ?? _destinationLatitude;
    final defaultLongitude = position?.longitude ?? _destinationLongitude;
    if (defaultLatitude == null || defaultLongitude == null) return;

    _liveMapBloc.add(
      InitializeMapEvent(
        controller: controller,
        defaultLatitude: defaultLatitude,
        defaultLongitude: defaultLongitude,
        routeColor: context.colorScheme.primary,
      ),
    );

    if (!_isLoading) {
      _triggerDrawRoute(defaultLatitude, defaultLongitude);
    }
  }

  void _showActionError(String message) {
    if (!mounted || AppNetworkStatusScope.isUnavailableOf(context)) return;
    AppSnackBar.show(context, message, isError: true);
  }

  Future<void> _completeTrip(BuildContext context) async {
    if (_isCompletingTrip) return;
    final rideCubit = BlocProvider.of<RideFlowCubit>(context);
    setState(() => _isCompletingTrip = true);
    try {
      final position = await LocationService.getCurrentPosition();
      if (!mounted) return;
      if (position == null) {
        _showActionError(
          'Your location is unavailable. Enable location and try again.',
        );
        return;
      }
      final finalFare = await rideCubit.completeRide(
        driverLatitude: position.latitude,
        driverLongitude: position.longitude,
      );
      if (finalFare == null) {
        _showActionError(
          rideCubit.lastActionFailureMessage ??
              rideCubit.state.failureMessage ??
              'The trip could not be completed. Please try again.',
        );
        return;
      }
      if (!mounted) return;
      this.context.pushReplacementNamed(
        ActiveRideRoutes.fareSummary,
        extra: {
          'rideId': rideCubit.activeRideId,
          'bookingReference': rideCubit.activeBookingReference,
          'pickup': widget.pickup,
          'dropoff': widget.dropoff,
          'distance': widget.distance,
          'fare': finalFare,
          'duration': widget.duration,
        },
      );
    } catch (error) {
      _showActionError(ErrorHandler.getErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _isCompletingTrip = false;
          _completionSliderProgress = 0;
        });
      }
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
          final defaultLatitude =
              position?.latitude ??
              rideCubitState.destinationLatitude ??
              _destinationLatitude;
          final defaultLongitude =
              position?.longitude ??
              rideCubitState.destinationLongitude ??
              _destinationLongitude;
          if (defaultLatitude == null || defaultLongitude == null) {
            return const PopScope(
              canPop: false,
              child: Scaffold(
                body: Center(
                  child: Text('Destination location is unavailable.'),
                ),
              ),
            );
          }

          return PopScope(
            canPop: false,
            child: Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(
                    child: SizedBox.expand(
                      child: MapProvider.buildMapView(
                        latitude: defaultLatitude,
                        longitude: defaultLongitude,
                        zoom: 15.0,
                        onMapCreated: _onMapCreated,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: ActiveRideHeader(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      backButton: _buildTripBackButton(
                        context,
                        () => context.pop(),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SafeArea(
                      top: false,
                      child: LayoutBuilder(
                        builder: (context, constraints) => ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: constraints.maxHeight * 0.65,
                            maxWidth: 600,
                          ),
                          child: SingleChildScrollView(
                            child: Container(
                              decoration: BoxDecoration(
                                color: context.colorScheme.surface,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppRadius.sheet),
                                ),
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                10,
                                AppSpacing.lg,
                                AppSpacing.lg,
                              ),
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
                                  CompactRouteTimeline(
                                    pickup: widget.pickup,
                                    dropoff: widget.dropoff,
                                    pickupLabel: 'Pickup',
                                    dropoffLabel: 'Drop Off',
                                  ),
                                  const SizedBox(height: 8),
                                  const InTransitPassengerCard(),
                                  const SizedBox(height: 12),
                                  InTransitCompletionSlider(
                                    progress: _completionSliderProgress,
                                    onProgressChanged: (progress) {
                                      if (mounted) {
                                        setState(
                                          () => _completionSliderProgress =
                                              progress,
                                        );
                                      }
                                    },
                                    isCompletingTrip: _isCompletingTrip,
                                    onCompleteTripPressed: () =>
                                        _completeTrip(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
          width: AppSize.minimumTouchTarget,
          height: AppSize.minimumTouchTarget,
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

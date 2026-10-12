import 'package:maps/maps.dart';

import 'dart:async';

import 'package:driver/src/features/active_ride/active_ride_routes.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver/src/features/active_ride/domain/repositories/driver_ride_repository.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/in_transit/in_transit_completion_slider.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/in_transit/in_transit_passenger_card.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/driver_active_ride_header.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/driver_safety_report_sheet.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/driver_emergency_button.dart';
import 'package:driver/src/features/dashboard/dashboard_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:foundation/foundation.dart';
import 'package:design_system/design_system.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class const InTransitPage({
  super.key,
  required this.pickup,
  required this.dropoff,
  required this.distance,
  required this.fare,
  required this.duration,
  required this.rideRepository,
  required this.lifecycleCoordinator,
  required this.liveMapBloc,
}) extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final String duration;
  final double distance;
  final double fare;
  final DriverRideRepository rideRepository;
  final AppLifecycleCoordinator lifecycleCoordinator;
  final LiveMapBloc liveMapBloc;

  @override
  State<InTransitPage> createState() => _InTransitPageState();
}

class _InTransitPageState extends State<InTransitPage> {
  bool _isLoading = true;
  bool _isCompletingTrip = false;
  double _completionSliderProgress = 0;
  double? _destLat;
  double? _destLng;
  late final AppLifecyclePeriodicTask _trackingTask;
  late final LiveMapBloc _liveMapBloc;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    unawaited(WakelockPlus.enable());
    _liveMapBloc = widget.liveMapBloc;
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
      final rideCubit = BlocProvider.of<RideFlowCubit>(context);
      await rideCubit.refreshPassengerLocation();
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
          final rideState = rideCubit.state;
          _liveMapBloc.add(
            UpdateLocationsAndDrawRouteEvent(
              driverLat: pos.latitude,
              driverLng: pos.longitude,
              passengerLat: rideState.passengerLatitude,
              passengerLng: rideState.passengerLongitude,
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
      var rideState = rideCubit.state;
      // Resolve the destination before waiting on driver location so a
      // delayed permission response cannot prevent the destination leg from
      // being rendered.
      final destination = rideState.destinationCoordinates;
      if (destination != null) {
        final (destinationLat, destinationLng) = destination;
        _destLat = destinationLat;
        _destLng = destinationLng;
      } else {
        final places = await MapProvider.searchPlaces(widget.dropoff);
        if (places.isNotEmpty) {
          _destLat = places.first.latitude;
          _destLng = places.first.longitude;
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

  void _triggerDrawRoute(double dLat, double dLng) {
    final destinationLat = _destLat;
    final destinationLng = _destLng;
    if (destinationLat == null || destinationLng == null) return;
    final rideState = BlocProvider.of<RideFlowCubit>(context).state;
    _liveMapBloc.add(
      UpdateLocationsAndDrawRouteEvent(
        driverLat: dLat,
        driverLng: dLng,
        passengerLat: rideState.passengerLatitude,
        passengerLng: rideState.passengerLongitude,
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
    final rideCubit = BlocProvider.of<RideFlowCubit>(context);
    setState(() => _isCompletingTrip = true);
    try {
      final position = await LocationService.getCurrentPosition();
      if (!mounted) return;
      if (position == null) {
        CustomToast.show(
          this.context,
          'Your current location is unavailable. Enable location and try again.',
          isError: true,
        );
        return;
      }
      final finalFare = await rideCubit.completeRide(
        driverLat: position.latitude,
        driverLng: position.longitude,
      );
      if (finalFare == null) {
        if (mounted) {
          final state = rideCubit.state;
          CustomToast.show(
            this.context,
            state is RideFlowError
                ? state.message
                : 'Unable to complete the trip. Please try again.',
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
      if (mounted) {
        setState(() {
          _isCompletingTrip = false;
          _completionSliderProgress = 0;
        });
      }
    }
  }

  Future<bool> _emergencyStop(String reason, String details) async {
    if (!mounted) return false;
    final stopped = await BlocProvider.of<RideFlowCubit>(context)
        .emergencyStop(reason: reason, details: details);
    if (!stopped && mounted) {
      CustomToast.show(
        context,
        'The ride could not be ended for safety. Please try again.',
        isError: true,
      );
    }
    return stopped;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LiveMapBloc>.value(
      value: _liveMapBloc,
      child: Builder(
        builder: (context) {
          final rideCubitState = BlocProvider.of<RideFlowCubit>(context).state;
          final position = LocationService.lastPosition;
          final defaultLat =
              position?.latitude ??
              rideCubitState.destinationLatitude ??
              _destLat;
          final defaultLng =
              position?.longitude ??
              rideCubitState.destinationLongitude ??
              _destLng;
          if (defaultLat == null || defaultLng == null) {
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
                        latitude: defaultLat,
                        longitude: defaultLng,
                        zoom: 15.0,
                        onMapCreated: _onMapCreated,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: DriverActiveRideHeader(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      backButton: _buildTripBackButton(
                        context,
                        () => context.pop(),
                      ),
                      actions: [
                        DriverEmergencyButton(
                          onEmergencyStop: _emergencyStop,
                          onEmergencyStopCompleted: () {
                            if (mounted) {
                              context.goNamed(DashboardRoutes.dashboard);
                            }
                          },
                        ),
                        DriverSafetyReportButton(
                          rideId: BlocProvider.of<RideFlowCubit>(context)
                              .activeRideId,
                          rideRepository: widget.rideRepository,
                        ),
                      ],
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
                            top: Radius.circular(EasyRideRadius.sheet),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(
                          EasyRideSpacing.lg,
                          10,
                          EasyRideSpacing.lg,
                          EasyRideSpacing.lg,
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
                            CompactRouteTimelineWidget(
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
                                    () => _completionSliderProgress = progress,
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
          width: EasyRideSize.minimumTouchTarget,
          height: EasyRideSize.minimumTouchTarget,
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

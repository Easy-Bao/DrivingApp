import 'dart:async';

import 'package:driver_app/src/core/services/background_telemetry_service.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:maps/maps.dart';
import 'package:driver_app/src/app/navigation/app_routes.dart';
import 'package:driver_app/src/features/location/presentation/bloc/location_access/driver_location_access_cubit.dart';
import 'package:driver_app/src/features/location/presentation/bloc/location_access/driver_location_access_state.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver_app/src/features/trip/domain/repositories/i_driver_ride_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_core/shared_core.dart';
import 'package:design_system/design_system.dart';

class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> with WidgetsBindingObserver {
  late final DriverLocationAccessCubit _locationAccessCubit;
  late final AppLifecycleCoordinator _lifecycleCoordinator;
  late final NetworkAvailabilityCoordinator _networkAvailabilityCoordinator;
  bool _locationMonitoringRequested = false;

  @override
  void initState() {
    super.initState();
    _locationAccessCubit = Modular.get<DriverLocationAccessCubit>();
    _lifecycleCoordinator = Modular.get<AppLifecycleCoordinator>();
    _networkAvailabilityCoordinator =
        Modular.get<NetworkAvailabilityCoordinator>();
    WidgetsBinding.instance.addObserver(this);
    Modular.routerConfig.routerDelegate.addListener(_onRouteChanged);
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (lifecycleState != null) {
      _lifecycleCoordinator.update(
        isForeground: lifecycleState == AppLifecycleState.resumed,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureLocationMonitoring();
      unawaited(_setBackgroundTelemetryVisibility(true));
    });
  }

  @override
  void dispose() {
    unawaited(_setBackgroundTelemetryVisibility(false));
    Modular.routerConfig.routerDelegate.removeListener(_onRouteChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleCoordinator.update(
      isForeground: state == AppLifecycleState.resumed,
    );
    unawaited(
      _setBackgroundTelemetryVisibility(state == AppLifecycleState.resumed),
    );
    if (state == AppLifecycleState.resumed) {
      _ensureLocationMonitoring();
      unawaited(_locationAccessCubit.refresh());
    }
  }

  void _onRouteChanged() {
    if (mounted) _ensureLocationMonitoring();
  }

  Future<void> _setBackgroundTelemetryVisibility(bool isVisible) async {
    try {
      await Modular.get<BackgroundTelemetryService>().setAppVisible(isVisible);
    } catch (_) {
      // The application can reach its first frame before service bindings are
      // ready. A later lifecycle event or service configuration will sync it.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DriverLocationAccessCubit>.value(
          value: _locationAccessCubit,
        ),
        BlocProvider<RideFlowCubit>(
          create: (_) => RideFlowCubit(
            rideRepository: Modular.get<IDriverRideRepository>(),
            sessionService: Modular.get<SecureSessionService>(),
          ),
        ),
      ],
      child:
          BlocBuilder<DriverLocationAccessCubit, DriverLocationAccessViewState>(
            builder: (context, locationState) => ModularApp.router(
              theme: EasyRideTheme.light,
              debugShowCheckedModeBanner: false,
              title: 'BaoRide Driver',
              builder: (context, child) =>
                  StreamBuilder<NetworkAvailabilityStatus>(
                    stream: _networkAvailabilityCoordinator.changes,
                    initialData: _networkAvailabilityCoordinator.status,
                    builder: (context, snapshot) => Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildRouteWithLocationOverlay(
                          context,
                          child,
                          locationState,
                        ),
                        AppNetworkStatusBanner(
                          isVisible:
                              snapshot.data ==
                              NetworkAvailabilityStatus.unavailable,
                        ),
                      ],
                    ),
                  ),
            ),
          ),
    );
  }

  Widget _buildRouteWithLocationOverlay(
    BuildContext context,
    Widget? child,
    DriverLocationAccessViewState locationState,
  ) {
    final overlay = _buildLocationOverlay(context, locationState);
    return Stack(
      fit: StackFit.expand,
      children: [child ?? const SizedBox.shrink(), ?overlay],
    );
  }

  Widget? _buildLocationOverlay(
    BuildContext context,
    DriverLocationAccessViewState locationState,
  ) {
    final currentPath =
        Modular.routerConfig.routerDelegate.currentConfiguration.uri.path;
    if (!currentPath.startsWith(AppRoutes.driverModulePath)) return null;

    final cubit = BlocProvider.of<DriverLocationAccessCubit>(context);
    return switch (locationState) {
      DriverLocationAccessChecking() => const LocationAccessOverlay(
        state: LocationAccessOverlayState.checking,
        appName: 'BaoRide',
      ),
      DriverLocationAccessReady() => null,
      DriverLocationAccessUnavailable(
        accessState: final accessState,
        message: final message,
      ) =>
        switch (accessState) {
          LocationAccessState.ready => null,
          LocationAccessState.denied => LocationAccessOverlay(
            state: LocationAccessOverlayState.permissionDenied,
            appName: 'BaoRide',
            message: message,
            onTryAgain: () => unawaited(cubit.enable()),
          ),
          LocationAccessState.serviceDisabled => LocationAccessOverlay(
            state: LocationAccessOverlayState.serviceDisabled,
            appName: 'BaoRide',
            message: message,
            onOpenLocationSettings: () => unawaited(cubit.enable()),
            onTryAgain: () => unawaited(cubit.refresh()),
          ),
          LocationAccessState.deniedForever => LocationAccessOverlay(
            state: LocationAccessOverlayState.permissionDeniedForever,
            appName: 'BaoRide',
            message: message,
            onOpenAppSettings: () => unawaited(cubit.enable()),
            onTryAgain: () => unawaited(cubit.refresh()),
          ),
        },
    };
  }

  void _ensureLocationMonitoring() {
    final currentPath =
        Modular.routerConfig.routerDelegate.currentConfiguration.uri.path;
    if (_locationMonitoringRequested ||
        !currentPath.startsWith(AppRoutes.driverModulePath)) {
      return;
    }

    _locationMonitoringRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isDriverRoute) {
        unawaited(_locationAccessCubit.start());
      }
    });
  }

  bool get _isDriverRoute => Modular
      .routerConfig
      .routerDelegate
      .currentConfiguration
      .uri
      .path
      .startsWith(AppRoutes.driverModulePath);
}

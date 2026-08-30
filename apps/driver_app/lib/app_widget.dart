import 'dart:async';

import 'package:driver_app/src/core/services/background_telemetry_service.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/core/location/location.dart';
import 'package:driver_app/src/core/routing/app_routes.dart';
import 'package:driver_app/src/features/location/bloc/location_access/driver_location_access_cubit.dart';
import 'package:driver_app/src/features/location/bloc/location_access/driver_location_access_state.dart';
import 'package:driver_app/src/features/trip/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver_app/src/features/trip/domain/repositories/i_driver_ride_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_ui/shared_ui.dart';

class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> with WidgetsBindingObserver {
  late final ThemeModeCubit _themeModeCubit;
  late final DriverLocationAccessCubit _locationAccessCubit;
  bool _locationMonitoringRequested = false;

  @override
  void initState() {
    super.initState();
    _themeModeCubit = Modular.get<ThemeModeCubit>();
    _locationAccessCubit = Modular.get<DriverLocationAccessCubit>();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureLocationMonitoring();
      unawaited(_setBackgroundTelemetryVisibility(true));
    });
  }

  @override
  void dispose() {
    unawaited(_setBackgroundTelemetryVisibility(false));
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(
      _setBackgroundTelemetryVisibility(state == AppLifecycleState.resumed),
    );
    if (state == AppLifecycleState.resumed) {
      _ensureLocationMonitoring();
      unawaited(_locationAccessCubit.refresh());
    }
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
        BlocProvider<ThemeModeCubit>.value(value: _themeModeCubit),
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
      child: BlocBuilder<ThemeModeCubit, ThemeMode>(
        builder: (context, themeMode) =>
            BlocBuilder<
              DriverLocationAccessCubit,
              DriverLocationAccessViewState
            >(
              builder: (context, locationState) => ModularApp.router(
                theme: EasyRideTheme.light,
                darkTheme: EasyRideTheme.dark,
                themeMode: themeMode,
                debugShowCheckedModeBanner: false,
                title: 'BaoRide Driver',
                builder: (context, child) => _buildRouteWithLocationOverlay(
                  context,
                  child,
                  locationState,
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

    _ensureLocationMonitoring();
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
      if (mounted) unawaited(_locationAccessCubit.start());
    });
  }
}

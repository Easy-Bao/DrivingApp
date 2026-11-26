import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:driver/src/app/navigation/app_routes.dart';
import 'package:driver/src/core/session/session_store.dart';
import 'package:driver/src/core/telemetry/background_telemetry.dart';
import 'package:driver/src/features/active_ride/domain/repositories/ride_repository.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver/src/features/settings/settings_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart';

class const App({super.key}) extends StatefulWidget {
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  late final LocationAccessCubit _locationAccessCubit;
  late final AppLifecycleCoordinator _lifecycleCoordinator;
  bool _locationMonitoringRequested = false;

  @override
  void initState() {
    super.initState();
    _locationAccessCubit = Modular.get<LocationAccessCubit>();
    _lifecycleCoordinator = Modular.get<AppLifecycleCoordinator>();
    WidgetsBinding.instance.addObserver(this);
    Modular.routerConfig.routerDelegate.addListener(_onRouteChanged);
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (lifecycleState != null) {
      _lifecycleCoordinator.update(
        isForeground: lifecycleState == AppLifecycleState.resumed,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
      MapProvider.clearLookupCaches();
      _ensureLocationMonitoring();
      unawaited(_locationAccessCubit.refresh());
    }
  }

  void _onRouteChanged() {
    if (mounted) _ensureLocationMonitoring();
  }

  Future<void> _setBackgroundTelemetryVisibility(bool isVisible) async {
    try {
      await Modular.get<BackgroundTelemetry>().setAppVisible(isVisible);
    } catch (_) {
      // The application can reach its first frame before service bindings are
      // ready. A later lifecycle event or service configuration will sync it.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LocationAccessCubit>.value(value: _locationAccessCubit),
        BlocProvider<RideFlowCubit>(
          create: (_) => RideFlowCubit(
            rideRepository: Modular.get<RideRepository>(),
            sessionService: Modular.get<SessionStore>(),
          ),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: Modular.routerConfig,
        theme: AppTheme.main,
        debugShowCheckedModeBanner: false,
        title: 'EasyRide Driver',
        // Keep legacy Material Theme/Localizations available to dependencies
        // (such as go_router 17, go_transitions, skeletonizer, and fl_chart)
        // until they adopt package:material_ui.
        // ignore: deprecated_member_use
        builder: (context, child) => MaterialUiCompatibilityBridge(
          child: LocationAccessOverlayScope(
            enabled: _requiresLocationAccess,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  void _ensureLocationMonitoring() {
    if (_locationMonitoringRequested || !_requiresLocationAccess) {
      return;
    }

    _locationMonitoringRequested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _requiresLocationAccess) {
        unawaited(_locationAccessCubit.start());
      }
    });
  }

  bool get _requiresLocationAccess {
    final currentPath =
        Modular.routerConfig.routerDelegate.currentConfiguration.uri.path;
    return currentPath.startsWith(AppRoutes.driverModulePath) &&
        !currentPath.endsWith('/${SettingsRoutes.termsPath}');
  }
}

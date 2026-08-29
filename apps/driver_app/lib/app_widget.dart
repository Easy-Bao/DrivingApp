import 'dart:async';

import 'package:driver_app/src/core/location/location.dart';
import 'package:driver_app/src/core/services/background_telemetry_service.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
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

  @override
  void initState() {
    super.initState();
    _themeModeCubit = Modular.get<ThemeModeCubit>();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
      unawaited(LocationService.refresh());
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
        BlocProvider<RideFlowCubit>(
          create: (_) => RideFlowCubit(
            rideRepository: Modular.get<IDriverRideRepository>(),
            sessionService: Modular.get<SecureSessionService>(),
          ),
        ),
      ],
      child: BlocBuilder<ThemeModeCubit, ThemeMode>(
        builder: (context, themeMode) => ModularApp.router(
          theme: EasyRideTheme.light,
          darkTheme: EasyRideTheme.dark,
          themeMode: themeMode,
          debugShowCheckedModeBanner: false,
          title: 'BaoRide Driver',
        ),
      ),
    );
  }
}

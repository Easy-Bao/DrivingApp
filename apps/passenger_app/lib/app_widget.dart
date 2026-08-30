import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/location/location.dart';
import 'package:passenger_app/src/core/routing/app_routes.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/auth/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/location/bloc/location_access/location_access_cubit.dart';
import 'package:passenger_app/src/features/location/bloc/location_access/location_access_state.dart';
import 'package:passenger_app/src/features/trip/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:passenger_app/src/features/trip/bloc/track_driver/track_driver_cubit.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_track_repository.dart';
import 'package:shared_ui/shared_ui.dart';

class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> with WidgetsBindingObserver {
  late final SessionBloc _sessionBloc;
  late final LocationAccessCubit _locationAccessCubit;
  late final ThemeModeCubit _themeModeCubit;

  @override
  void initState() {
    super.initState();
    _sessionBloc = Modular.get<SessionBloc>()..add(const SessionStarted());
    _locationAccessCubit = Modular.get<LocationAccessCubit>();
    _themeModeCubit = Modular.get<ThemeModeCubit>();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_locationAccessCubit.start());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == .resumed) {
      unawaited(_locationAccessCubit.refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SessionBloc>.value(value: _sessionBloc),
        BlocProvider<LocationAccessCubit>.value(value: _locationAccessCubit),
        BlocProvider<ThemeModeCubit>.value(value: _themeModeCubit),
        BlocProvider<BookingDraftCubit>.value(
          value: Modular.get<BookingDraftCubit>(),
        ),
        BlocProvider<TrackDriverCubit>(
          create: (_) {
            return TrackDriverCubit(
              repository: Modular.get<ITrackRepository>(),
              sessionService: Modular.get<SecureSessionService>(),
            );
          },
        ),
      ],
      child: BlocBuilder<ThemeModeCubit, ThemeMode>(
        builder: (context, themeMode) =>
            BlocBuilder<LocationAccessCubit, LocationAccessViewState>(
              builder: (context, locationState) => ModularApp.router(
                theme: EasyRideTheme.light,
                darkTheme: EasyRideTheme.dark,
                themeMode: themeMode,
                debugShowCheckedModeBanner: false,
                title: 'EasyRide Passenger',
                builder: (context, child) => MultiBlocListener(
                  listeners: [
                    BlocListener<SessionBloc, SessionState>(
                      listenWhen: (_, current) =>
                          current is GuestSession || current is SessionFailure,
                      listener: (context, _) =>
                          BlocProvider.of<BookingDraftCubit>(context).clear(),
                    ),
                  ],
                  child: _buildRouteWithLocationOverlay(
                    context,
                    child,
                    locationState,
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildRouteWithLocationOverlay(
    BuildContext context,
    Widget? child,
    LocationAccessViewState locationState,
  ) {
    final overlay = _buildLocationOverlay(context, locationState);
    return Stack(
      fit: StackFit.expand,
      children: [child ?? const SizedBox.shrink(), ?overlay],
    );
  }

  Widget? _buildLocationOverlay(
    BuildContext context,
    LocationAccessViewState locationState,
  ) {
    final currentPath =
        Modular.routerConfig.routerDelegate.currentConfiguration.uri.path;
    if (!currentPath.startsWith(AppRoutes.passengerModulePath)) return null;

    final cubit = BlocProvider.of<LocationAccessCubit>(context);
    return switch (locationState) {
      LocationAccessChecking() => const LocationAccessOverlay(
        state: LocationAccessOverlayState.checking,
        appName: 'EasyRide',
      ),
      LocationAccessReady() => null,
      LocationAccessUnavailable(
        accessState: final accessState,
        message: final message,
      ) =>
        switch (accessState) {
          LocationAccessState.ready => null,
          LocationAccessState.denied => LocationAccessOverlay(
            state: LocationAccessOverlayState.permissionDenied,
            appName: 'EasyRide',
            message: message,
            onTryAgain: () => unawaited(cubit.enable()),
          ),
          LocationAccessState.serviceDisabled => LocationAccessOverlay(
            state: LocationAccessOverlayState.serviceDisabled,
            appName: 'EasyRide',
            message: message,
            onOpenLocationSettings: () => unawaited(cubit.enable()),
            onTryAgain: () => unawaited(cubit.refresh()),
          ),
          LocationAccessState.deniedForever => LocationAccessOverlay(
            state: LocationAccessOverlayState.permissionDeniedForever,
            appName: 'EasyRide',
            message: message,
            onOpenAppSettings: () => unawaited(cubit.enable()),
            onTryAgain: () => unawaited(cubit.refresh()),
          ),
        },
    };
  }
}

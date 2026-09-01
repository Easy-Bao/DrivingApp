import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/app/navigation/app_routes.dart';
import 'package:passenger/src/app/theme/app_theme.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/location/presentation/bloc/location_access/location_access_cubit.dart';
import 'package:passenger/src/features/location/presentation/bloc/location_access/location_access_state.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver/track_driver_cubit.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:foundation/foundation.dart';
import 'package:design_system/design_system.dart';

class const PassengerApp({super.key}) extends StatefulWidget {
  @override
  State<PassengerApp> createState() => _PassengerAppState();
}

class _PassengerAppState extends State<PassengerApp>
    with WidgetsBindingObserver {
  late final SessionBloc _sessionBloc;
  late final LocationAccessCubit _locationAccessCubit;
  late final AppLifecycleCoordinator _lifecycleCoordinator;
  late final NetworkAvailabilityCoordinator _networkAvailabilityCoordinator;

  @override
  void initState() {
    super.initState();
    _sessionBloc = Modular.get<SessionBloc>()..add(const SessionStarted());
    _locationAccessCubit = Modular.get<LocationAccessCubit>();
    _lifecycleCoordinator = Modular.get<AppLifecycleCoordinator>();
    _networkAvailabilityCoordinator =
        Modular.get<NetworkAvailabilityCoordinator>();
    WidgetsBinding.instance.addObserver(this);
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (lifecycleState != null) {
      _lifecycleCoordinator.update(
        isForeground: lifecycleState == AppLifecycleState.resumed,
      );
    }
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
    _lifecycleCoordinator.update(
      isForeground: state == AppLifecycleState.resumed,
    );
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
        BlocProvider<BookingDraftCubit>.value(
          value: Modular.get<BookingDraftCubit>(),
        ),
        BlocProvider<TrackDriverCubit>(
          create: (_) {
            return TrackDriverCubit(
              repository: Modular.get<TrackRepository>(),
              sessionService: Modular.get<PassengerSessionStore>(),
              lifecycleCoordinator: _lifecycleCoordinator,
            );
          },
        ),
      ],
      child: BlocBuilder<LocationAccessCubit, LocationAccessViewState>(
        builder: (context, locationState) => ModularApp.router(
          theme: AppTheme.data,
          debugShowCheckedModeBanner: false,
          title: 'EasyRide Passenger',
          builder: (context, child) => StreamBuilder<NetworkAvailabilityStatus>(
            stream: _networkAvailabilityCoordinator.changes,
            initialData: _networkAvailabilityCoordinator.status,
            builder: (context, snapshot) => Stack(
              fit: StackFit.expand,
              children: [
                MultiBlocListener(
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
                AppNetworkStatusBanner(
                  isVisible:
                      snapshot.data == NetworkAvailabilityStatus.unavailable,
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

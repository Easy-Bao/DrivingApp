import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/app/navigation/app_routes.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/core/telemetry/background_telemetry.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver_cubit.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:passenger/src/features/profile/domain/repositories/profile_repository.dart';
import 'package:passenger/src/features/profile/presentation/bloc/profile_cubit.dart';

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  late final SessionBloc _sessionBloc;
  late final LocationAccessCubit _locationAccessCubit;
  late final AppLifecycleCoordinator _lifecycleCoordinator;
  NetworkAvailabilityCoordinator? _networkAvailability;

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
              sessionService: Modular.get<SessionStore>(),
              lifecycleCoordinator: _lifecycleCoordinator,
              backgroundTelemetryService: Modular.get<BackgroundTelemetry>(),
            );
          },
        ),
      ],
      child: MaterialApp.router(
        routerConfig: Modular.routerConfig,
        theme: AppTheme.main,
        debugShowCheckedModeBanner: false,
        title: 'EasyRide Passenger',
        builder: (context, child) {
          final content = MultiBlocListener(
            listeners: [
              BlocListener<SessionBloc, SessionState>(
                listenWhen: (_, current) =>
                    current is GuestSession || current is SessionFailure,
                listener: (context, _) {
                  MapProvider.clearLookupCaches();
                  BlocProvider.of<BookingDraftCubit>(context).clear();
                  unawaited(
                    BlocProvider.of<TrackDriverCubit>(context).resetTracking(),
                  );
                  try {
                    Modular.get<BookingBloc>().add(const CancelBookingEvent());
                  } catch (_) {}
                  try {
                    Modular.get<ProfileRepository>().clearCachedProfile();
                  } catch (_) {}
                  try {
                    Modular.get<ProfileCubit>().reset();
                  } catch (_) {}
                  try {
                    unawaited(
                      Modular.get<BackgroundTelemetry>().stopRideTelemetry(),
                    );
                  } catch (_) {}
                },
              ),
            ],
            child: LocationAccessOverlayScope(
              enabled: _isPassengerRoute,
              child: child ?? const SizedBox.shrink(),
            ),
          );
          final networkAvailability = _networkAvailability;
          // Keep legacy Material Theme/Localizations available to dependencies
          // (such as go_router 17, go_transitions, and skeletonizer) until they
          // adopt package:material_ui.
          // ignore: deprecated_member_use
          return MaterialUiCompatibilityBridge(
            child: networkAvailability == null
                ? content
                : AppNetworkStatusHost(
                    coordinator: networkAvailability,
                    child: content,
                  ),
          );
        },
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleCoordinator.update(
      isForeground: state == AppLifecycleState.resumed,
    );
    if (state == .resumed) {
      MapProvider.clearLookupCaches();
      unawaited(_locationAccessCubit.refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _sessionBloc = Modular.get<SessionBloc>()..add(const SessionStarted());
    _locationAccessCubit = Modular.get<LocationAccessCubit>();
    _lifecycleCoordinator = Modular.get<AppLifecycleCoordinator>();
    try {
      _networkAvailability = Modular.get<NetworkAvailabilityCoordinator>();
    } catch (_) {
      // Tests that mount App without full dependency registration may omit
      // the global network availability coordinator.
    }
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

  bool get _isPassengerRoute => Modular
      .routerConfig
      .routerDelegate
      .currentConfiguration
      .uri
      .path
      .startsWith(AppRoutes.passengerModulePath);
}

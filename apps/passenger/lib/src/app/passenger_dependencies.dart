import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/app/navigation/app_routes.dart';
import 'package:passenger/src/app/passenger_router.dart';
import 'package:passenger/src/features/auth/auth_module.dart';
import 'package:passenger/src/features/auth/data/repositories/session_repository_impl.dart';
import 'package:passenger/src/features/auth/domain/repositories/session_repository.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:passenger/src/features/location/data/repositories/location_access_repository_impl.dart';
import 'package:passenger/src/features/location/domain/repositories/location_access_repository.dart';
import 'package:passenger/src/features/location/presentation/bloc/location_access/location_access_cubit.dart';
import 'package:passenger/src/infrastructure/config/passenger_env_config.dart';
import 'package:passenger/src/infrastructure/network/passenger_api_client.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';
import 'package:passenger/src/infrastructure/telemetry/passenger_background_telemetry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PassengerDependencies({required this._prefs}) extends Module {
  final SharedPreferences _prefs;

  @override
  void binds(Injector i) {
    i
      ..addSingleton<SharedPreferences>((i) => _prefs)
      ..addLazySingleton<AppLifecycleCoordinator>(
        (_) => AppLifecycleCoordinator(),
      )
      ..addLazySingleton<NetworkAvailabilityCoordinator>(
        (_) => NetworkAvailabilityCoordinator(),
      )
      ..addLazySingleton<PassengerSessionStore>((i) => PassengerSessionStore())
      ..addLazySingleton<PassengerBackgroundTelemetry>(
        (i) => PassengerBackgroundTelemetry(
          apiBaseUri: PassengerEnvConfig.apiBaseUri,
          lifecycleCoordinator: i.get<AppLifecycleCoordinator>(),
        ),
      )
      ..addLazySingleton<SessionRepository>(
        (i) => SessionRepositoryImpl(
          secureSessionService: i.get<PassengerSessionStore>(),
          preferences: i.get<SharedPreferences>(),
        ),
      )
      ..addLazySingleton<SessionBloc>(
        (i) => SessionBloc(sessionRepository: i.get<SessionRepository>()),
      )
      ..addLazySingleton<LocationAccessRepository>(
        (_) => LocationAccessRepositoryImpl(),
      )
      ..addLazySingleton<LocationAccessCubit>(
        (i) =>
            LocationAccessCubit(repository: i.get<LocationAccessRepository>()),
      )
      ..addLazySingleton<Dio>(
        (i) => PassengerApiClient.create(
          baseUrl: PassengerEnvConfig.apiBaseUri,
          sessionService: i.get<PassengerSessionStore>(),
          networkAvailability: i.get<NetworkAvailabilityCoordinator>(),
          onSessionExpired: () =>
              i.get<SessionBloc>().add(const SessionGuestRequested()),
        ),
      )
      ..addLazySingleton<LocationRepository>(
        (i) => LocationRemoteDataSource(i.get<Dio>()),
      )
      // PassengerApp provides this state before the passenger route module is active.
      ..addLazySingleton<BookingDraftCubit>((_) => BookingDraftCubit());
  }

  @override
  List<ModularRoute> get routes => [
    ModuleRoute(AppRoutes.authModulePath, module: AuthModule()),
    ModuleRoute(AppRoutes.passengerModulePath, module: PassengerRouter()),
  ];
}

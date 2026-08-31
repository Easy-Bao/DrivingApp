import 'package:dio/dio.dart';
import 'package:maps/maps.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/passenger_module.dart';
import 'package:passenger_app/src/infrastructure/config/passenger_env_config.dart';
import 'package:passenger_app/src/infrastructure/network/passenger_api_client.dart';
import 'package:passenger_app/src/app/navigation/app_routes.dart';
import 'package:passenger_app/src/infrastructure/telemetry/passenger_background_telemetry.dart';
import 'package:passenger_app/src/infrastructure/session/passenger_session_store.dart';
import 'package:passenger_app/src/features/auth/auth_module.dart';
import 'package:passenger_app/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/auth/data/repositories/session_repository_impl.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/session_repository.dart';
import 'package:passenger_app/src/features/location/presentation/bloc/location_access/location_access_cubit.dart';
import 'package:passenger_app/src/features/location/data/repositories/location_access_repository.dart';
import 'package:passenger_app/src/features/location/domain/repositories/i_location_access_repository.dart';
import 'package:passenger_app/src/features/booking/presentation/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:foundation/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppModule extends Module {
  final SharedPreferences _prefs;

  AppModule({required SharedPreferences prefs}) : _prefs = prefs;

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
      ..addLazySingleton<ILocationAccessRepository>(
        (_) => LocationAccessRepository(),
      )
      ..addLazySingleton<LocationAccessCubit>(
        (i) =>
            LocationAccessCubit(repository: i.get<ILocationAccessRepository>()),
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
      // AppWidget provides this state before the passenger route module is active.
      ..addLazySingleton<BookingDraftCubit>((_) => BookingDraftCubit());
  }

  @override
  List<ModularRoute> get routes => [
    ModuleRoute(AppRoutes.authModulePath, module: AuthModule()),
    ModuleRoute(AppRoutes.passengerModulePath, module: PassengerModule()),
  ];
}

import 'package:dio/dio.dart';
import 'package:maps/maps.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/passenger_module.dart';
import 'package:passenger_app/src/core/constants/env_config.dart';
import 'package:passenger_app/src/core/network/dio_client.dart';
import 'package:passenger_app/src/app/navigation/app_routes.dart';
import 'package:passenger_app/src/core/services/background_telemetry_service.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/core/storage/secure_storage.dart';
import 'package:passenger_app/src/features/auth/auth_module.dart';
import 'package:passenger_app/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:passenger_app/src/features/auth/data/repositories/session_repository_impl.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/session_repository.dart';
import 'package:passenger_app/src/features/location/presentation/bloc/location_access/location_access_cubit.dart';
import 'package:passenger_app/src/features/location/data/repositories/location_access_repository.dart';
import 'package:passenger_app/src/features/location/domain/repositories/i_location_access_repository.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:shared_core/shared_core.dart';
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
      ..addLazySingleton<SecureSessionService>((i) => SecureSessionService())
      ..addLazySingleton<BackgroundTelemetryService>(
        (i) => BackgroundTelemetryService(
          apiBaseUri: EnvConfig.apiBaseUri,
          lifecycleCoordinator: i.get<AppLifecycleCoordinator>(),
        ),
      )
      ..addLazySingleton<SecureStorage>(
        (i) => SecureStorage(i.get<SecureSessionService>()),
      )
      ..addLazySingleton<SessionRepository>(
        (i) => SessionRepositoryImpl(
          secureSessionService: i.get<SecureSessionService>(),
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
        (i) => DioClient.create(
          baseUrl: EnvConfig.apiBaseUri,
          sessionService: i.get<SecureSessionService>(),
          networkAvailability: i.get<NetworkAvailabilityCoordinator>(),
          onSessionExpired: () =>
              i.get<SessionBloc>().add(const SessionGuestRequested()),
        ),
      )
      ..addLazySingleton<IChatRepositoryFactory>(
        (i) => ChatRepositoryFactory(
          clientDio: i.get<Dio>(),
          tokenProvider: i.get<SecureSessionService>().readToken,
        ),
      )
      ..addLazySingleton<LocationRepository>(
        (i) => LocationRemoteDataSource(i.get<Dio>()),
      )
      ..addLazySingleton<AuthRemoteDataSource>(
        (i) => AuthRemoteDataSourceImpl(i.get<Dio>()),
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

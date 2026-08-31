import 'package:auth/auth.dart';
import 'package:chat/chat.dart';
import 'package:dio/dio.dart';
import 'package:driver_app/driver_module.dart';
import 'package:driver_app/src/app/navigation/app_routes.dart';
import 'package:driver_app/src/core/constants/env_config.dart';
import 'package:driver_app/src/core/network/dio_client.dart';
import 'package:driver_app/src/core/services/background_telemetry_service.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/core/storage/secure_storage.dart';
import 'package:driver_app/src/features/auth/auth_module.dart';
import 'package:driver_app/src/features/auth/data/repositories/driver_auth_repository.dart';
import 'package:driver_app/src/features/auth/domain/repositories/driver_auth_repository.dart';
import 'package:driver_app/src/features/location/presentation/bloc/location_access/driver_location_access_cubit.dart';
import 'package:driver_app/src/features/location/data/repositories/driver_location_access_repository.dart';
import 'package:driver_app/src/features/location/domain/repositories/i_driver_location_access_repository.dart';
import 'package:driver_app/src/features/active_ride/data/data_sources/ride_counterparty_remote_data_source.dart';
import 'package:driver_app/src/features/active_ride/data/data_sources/ride_remote_data_source.dart';
import 'package:driver_app/src/features/active_ride/data/data_sources/telemetry_remote_data_source.dart';
import 'package:driver_app/src/features/active_ride/data/repositories/driver_ride_repository.dart';
import 'package:driver_app/src/features/active_ride/domain/repositories/i_driver_ride_repository.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppModule extends Module {
  final SharedPreferences _prefs;
  final SecureSessionService _sessionService;

  AppModule({
    required SharedPreferences prefs,
    SecureSessionService? sessionService,
  }) : _prefs = prefs,
       _sessionService = sessionService ?? SecureSessionService();

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
      ..addLazySingleton<IDriverLocationAccessRepository>(
        (_) => DriverLocationAccessRepository(),
      )
      ..addLazySingleton<DriverLocationAccessCubit>(
        (i) => DriverLocationAccessCubit(
          repository: i.get<IDriverLocationAccessRepository>(),
        ),
      )
      ..addLazySingleton<SecureSessionService>((i) => _sessionService)
      ..addLazySingleton<BackgroundTelemetryService>(
        (i) => BackgroundTelemetryService(
          apiBaseUri: EnvConfig.apiBaseUri,
          lifecycleCoordinator: i.get<AppLifecycleCoordinator>(),
          enabled: EnvConfig.backgroundTelemetryEnabled,
        ),
      )
      ..addLazySingleton<SecureStorage>(
        (i) => SecureStorage(i.get<SecureSessionService>()),
      )
      ..addLazySingleton<RealtimeWebSocketClient>(
        (i) => RealtimeWebSocketClient(
          uri: EnvConfig.webSocketBaseUri.replace(path: '/api/v1/realtime/ws'),
          tokenProvider: i.get<SecureSessionService>().readToken,
        ),
      )
      ..addLazySingleton<Dio>(
        (i) => DioClient.create(
          baseUrl: EnvConfig.apiBaseUri,
          sessionService: i.get<SecureSessionService>(),
          networkAvailability: i.get<NetworkAvailabilityCoordinator>(),
        ),
      )
      ..addLazySingleton<ChatRepositoryFactory>(
        (i) => DefaultChatRepositoryFactory(
          clientDio: i.get<Dio>(),
          tokenProvider: i.get<SecureSessionService>().readToken,
        ),
      )
      ..addLazySingleton<AuthRemoteDataSource>(
        (i) => DioAuthRemoteDataSource(i.get<Dio>()),
      )
      // Active ride state spans dashboard and active-ride routes, so its transport
      // remains at application scope while page-specific sources do not.
      ..addLazySingleton<RideRemoteDataSource>(
        (i) => RideRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<RideCounterpartyRemoteDataSource>(
        (i) => RideCounterpartyRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<TelemetryRemoteDataSource>(
        (i) => TelemetryRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<IDriverRideRepository>(
        (i) => DriverRideRepository(
          rideDataSource: i.get<RideRemoteDataSource>(),
          counterpartyDataSource: i.get<RideCounterpartyRemoteDataSource>(),
          telemetryDataSource: i.get<TelemetryRemoteDataSource>(),
        ),
      )
      ..addLazySingleton<DriverAuthRepository>(
        (i) => DriverAuthRepositoryImpl(
          remoteDataSource: i.get<AuthRemoteDataSource>(),
          secureSessionService: i.get<SecureSessionService>(),
        ),
      );
  }

  @override
  List<ModularRoute> get routes => [
    ModuleRoute(AppRoutes.authModulePath, module: AuthModule()),
    ModuleRoute(AppRoutes.driverModulePath, module: DriverModule()),
  ];
}

import 'package:dio/dio.dart';
import 'package:driver_app/driver_module.dart';
import 'package:driver_app/src/app/navigation/app_routes.dart';
import 'package:driver_app/src/infrastructure/config/driver_env_config.dart';
import 'package:driver_app/src/infrastructure/network/driver_api_client.dart';
import 'package:driver_app/src/infrastructure/telemetry/driver_background_telemetry.dart';
import 'package:driver_app/src/infrastructure/session/driver_session_store.dart';
import 'package:driver_app/src/features/auth/auth_module.dart';
import 'package:driver_app/src/features/location/presentation/bloc/location_access/driver_location_access_cubit.dart';
import 'package:driver_app/src/features/location/data/repositories/driver_location_access_repository.dart';
import 'package:driver_app/src/features/location/domain/repositories/i_driver_location_access_repository.dart';
import 'package:driver_app/src/features/active_ride/data/data_sources/ride_counterparty_remote_data_source.dart';
import 'package:driver_app/src/features/active_ride/data/data_sources/ride_remote_data_source.dart';
import 'package:driver_app/src/features/active_ride/data/data_sources/telemetry_remote_data_source.dart';
import 'package:driver_app/src/features/active_ride/data/repositories/driver_ride_repository.dart';
import 'package:driver_app/src/features/active_ride/domain/repositories/i_driver_ride_repository.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:foundation/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppModule extends Module {
  final SharedPreferences _prefs;
  final DriverSessionStore _sessionService;

  AppModule({
    required SharedPreferences prefs,
    DriverSessionStore? sessionService,
  }) : _prefs = prefs,
       _sessionService = sessionService ?? DriverSessionStore();

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
      ..addLazySingleton<DriverSessionStore>((i) => _sessionService)
      ..addLazySingleton<DriverBackgroundTelemetry>(
        (i) => DriverBackgroundTelemetry(
          apiBaseUri: DriverEnvConfig.apiBaseUri,
          lifecycleCoordinator: i.get<AppLifecycleCoordinator>(),
          enabled: DriverEnvConfig.backgroundTelemetryEnabled,
        ),
      )
      ..addLazySingleton<RealtimeWebSocketClient>(
        (i) => RealtimeWebSocketClient(
          uri: DriverEnvConfig.webSocketBaseUri.replace(path: '/api/v1/realtime/ws'),
          tokenProvider: i.get<DriverSessionStore>().readToken,
        ),
      )
      ..addLazySingleton<Dio>(
        (i) => DriverApiClient.create(
          baseUrl: DriverEnvConfig.apiBaseUri,
          sessionService: i.get<DriverSessionStore>(),
          networkAvailability: i.get<NetworkAvailabilityCoordinator>(),
        ),
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
      );
  }

  @override
  List<ModularRoute> get routes => [
    ModuleRoute(AppRoutes.authModulePath, module: AuthModule()),
    ModuleRoute(AppRoutes.driverModulePath, module: DriverModule()),
  ];
}

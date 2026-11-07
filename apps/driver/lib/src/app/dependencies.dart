import 'dart:async';

import 'package:dio/dio.dart';
import 'package:driver/src/app/router.dart';
import 'package:driver/src/app/navigation/app_routes.dart';
import 'package:driver/src/features/active_ride/data/datasources/ride_counterparty_remote_data_source.dart';
import 'package:driver/src/features/active_ride/data/datasources/ride_remote_data_source.dart';
import 'package:driver/src/features/active_ride/data/datasources/telemetry_remote_data_source.dart';
import 'package:driver/src/features/active_ride/data/repositories/ride_repository_impl.dart';
import 'package:driver/src/features/active_ride/domain/repositories/ride_repository.dart';
import 'package:driver/src/features/auth/auth_module.dart';
import 'package:driver/src/features/auth/auth_routes.dart';
import 'package:driver/src/core/location/location_access_cubit.dart';
import 'package:driver/src/core/config/env_config.dart';
import 'package:driver/src/core/network/api_client.dart';
import 'package:driver/src/core/session/session_store.dart';
import 'package:driver/src/core/telemetry/background_telemetry.dart';
import 'package:driver/src/core/telemetry/location_spool.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppDependencies extends Module {
  AppDependencies({required this.preferences, SessionStore? sessionService})
    : _sessionService = sessionService ?? SessionStore();

  final SharedPreferences preferences;
  final SessionStore _sessionService;

  @override
  void binds(Injector i) {
    i
      ..addSingleton<SharedPreferences>((i) => preferences)
      ..addLazySingleton<AppLifecycleCoordinator>(
        (_) => AppLifecycleCoordinator(),
      )
      ..addLazySingleton<NetworkAvailabilityCoordinator>(
        (_) => NetworkAvailabilityCoordinator(),
      )
      ..addLazySingleton<LocationAccessRepository>(
        (_) => DeviceLocationAccessRepository(),
      )
      ..addLazySingleton<LocationAccessCubit>(
        (i) =>
            LocationAccessCubit(repository: i.get<LocationAccessRepository>()),
      )
      ..addLazySingleton<SessionStore>((i) => _sessionService)
      ..addLazySingleton<RefreshableTokenProvider>((i) {
        final session = i.get<SessionStore>();
        return RefreshableTokenProvider(
          readAccessToken: session.readToken,
          readRefreshToken: session.readRefreshToken,
          saveAccessToken: session.saveToken,
          saveRefreshToken: session.saveRefreshToken,
          clearSession: session.clearSession,
          hasActiveMission: () async {
            final activeRideId = await session.readActiveRideId();
            return activeRideId != null && activeRideId.trim().isNotEmpty;
          },
          refreshClient: Dio(
            BaseOptions(
              baseUrl: EnvConfig.apiBaseUri.toString(),
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
            ),
          ),
          onSessionExpired: () => _navigateToSignIn(session),
        );
      })
      ..addLazySingleton<BackgroundTelemetry>(
        (i) => BackgroundTelemetry(
          apiBaseUri: EnvConfig.apiBaseUri,
          lifecycleCoordinator: i.get<AppLifecycleCoordinator>(),
          enabled: EnvConfig.backgroundTelemetryEnabled,
        ),
      )
      ..addLazySingleton<LocationSpool>((_) => LocationSpool())
      ..addLazySingleton<RealtimeWebSocketClient>(
        (i) => RealtimeWebSocketClient(
          uri: EnvConfig.webSocketBaseUri.replace(path: '/api/v1/realtime/ws'),
          tokenProvider: i.get<RefreshableTokenProvider>().getToken,
          refreshToken: i.get<RefreshableTokenProvider>().refreshAccessToken,
          networkAvailability: i.get<NetworkAvailabilityCoordinator>(),
        ),
      )
      ..addLazySingleton<Dio>(
        (i) => ApiClient.create(
          baseUrl: EnvConfig.apiBaseUri,
          sessionService: i.get<SessionStore>(),
          networkAvailability: i.get<NetworkAvailabilityCoordinator>(),
          tokenProvider: i.get<RefreshableTokenProvider>(),
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
      ..addLazySingleton<RideRepository>(
        (i) => RideRepositoryImpl(
          rideDataSource: i.get<RideRemoteDataSource>(),
          counterpartyDataSource: i.get<RideCounterpartyRemoteDataSource>(),
          telemetryDataSource: i.get<TelemetryRemoteDataSource>(),
          locationSpool: i.get<LocationSpool>(),
        ),
      );
  }

  @override
  List<ModularRoute> get routes => [
    ModuleRoute(AppRoutes.authModulePath, module: AuthModule()),
    ModuleRoute(AppRoutes.driverModulePath, module: AppRouter()),
  ];
}

Future<void> _navigateToSignIn([SessionStore? sessionService]) async {
  try {
    final session = sessionService ?? Modular.get<SessionStore>();
    final activeRideId = await session.readActiveRideId();
    if (activeRideId != null && activeRideId.trim().isNotEmpty) {
      return;
    }
  } catch (_) {}
  final router = Modular.routerConfig;
  if (router.routerDelegate.currentConfiguration.uri.path ==
      AuthRoutes.signinPath) {
    return;
  }
  router.goNamed(AuthRoutes.signin);
}

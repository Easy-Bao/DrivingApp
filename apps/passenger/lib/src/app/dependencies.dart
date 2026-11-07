import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/app/navigation/app_routes.dart';
import 'package:passenger/src/app/router.dart';
import 'package:passenger/src/core/config/env_config.dart';
import 'package:passenger/src/core/location/location_access_cubit.dart';
import 'package:passenger/src/core/network/api_client.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/core/telemetry/background_telemetry.dart';
import 'package:passenger/src/features/auth/auth_module.dart';
import 'package:passenger/src/features/auth/data/repositories/session_repository_impl.dart';
import 'package:passenger/src/features/auth/domain/repositories/session_repository.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppDependencies extends Module {
  AppDependencies({required this._preferences, SessionStore? sessionService})
    : _sessionService = sessionService ?? SessionStore();

  final SharedPreferences _preferences;
  final SessionStore _sessionService;

  @override
  void binds(Injector i) {
    i
      ..addSingleton<SharedPreferences>((i) => _preferences)
      ..addLazySingleton<AppLifecycleCoordinator>(
        (_) => AppLifecycleCoordinator(),
      )
      ..addLazySingleton<NetworkAvailabilityCoordinator>(
        (_) => NetworkAvailabilityCoordinator(),
      )
      ..addLazySingleton<SessionStore>((i) => _sessionService)
      ..addLazySingleton<RefreshableTokenProvider>((i) {
        final session = i.get<SessionStore>();
        late final RefreshableTokenProvider provider;
        provider = RefreshableTokenProvider(
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
          onSessionExpired: () =>
              i.get<SessionBloc>().add(const SessionGuestRequested()),
        );
        session.onActiveRideCleared = provider.flushDeferredExpiry;
        return provider;
      })
      ..addLazySingleton<BackgroundTelemetry>(
        (i) => BackgroundTelemetry(
          apiBaseUri: EnvConfig.apiBaseUri,
          lifecycleCoordinator: i.get<AppLifecycleCoordinator>(),
        ),
      )
      ..addLazySingleton<SessionRepository>(
        (i) => SessionRepositoryImpl(
          secureSessionService: i.get<SessionStore>(),
          preferences: i.get<SharedPreferences>(),
        ),
      )
      ..addLazySingleton<SessionBloc>(
        (i) => SessionBloc(sessionRepository: i.get<SessionRepository>()),
      )
      ..addLazySingleton<LocationAccessRepository>(
        (_) => DeviceLocationAccessRepository(),
      )
      ..addLazySingleton<LocationAccessCubit>(
        (i) =>
            LocationAccessCubit(repository: i.get<LocationAccessRepository>()),
      )
      ..addLazySingleton<Dio>(
        (i) => ApiClient.create(
          baseUrl: EnvConfig.apiBaseUri,
          sessionService: i.get<SessionStore>(),
          networkAvailability: i.get<NetworkAvailabilityCoordinator>(),
          tokenProvider: i.get<RefreshableTokenProvider>(),
        ),
      )
      ..addLazySingleton<LocationRepository>(
        (i) => LocationRemoteDataSource(i.get<Dio>()),
      )
      // App provides this state before the passenger route module is active.
      ..addLazySingleton<BookingDraftCubit>((_) => BookingDraftCubit());
  }

  @override
  List<ModularRoute> get routes => [
    ModuleRoute(AppRoutes.authModulePath, module: AuthModule()),
    ModuleRoute(AppRoutes.passengerModulePath, module: AppRouter()),
  ];
}

import 'package:dio/dio.dart';
import 'package:driver_app/driver_module.dart';
import 'package:driver_app/src/core/network/dio_client.dart';
import 'package:driver_app/src/features/auth/auth_module.dart';
import 'package:driver_services/driver_services.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:session_service/session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppModule extends Module {
  final SharedPreferences _prefs;

  AppModule({required SharedPreferences prefs}) : _prefs = prefs;

  @override
  void binds(Injector i) {
    i
      ..addSingleton<SharedPreferences>((i) => _prefs)
      ..addLazySingleton<SecureSessionService>((i) => SecureSessionService())
      ..addLazySingleton<DriverSessionService>(
        (i) => DriverSessionService(
          secureSessionService: i.get<SecureSessionService>(),
          prefs: i.get<SharedPreferences>(),
        ),
      )
      ..addLazySingleton<Dio>(
        (i) => DioClient.create(
          baseUrl: EnvironmentConfig.driverServiceUri,
          sessionService: i.get<SecureSessionService>(),
        ),
      )
      ..addLazySingleton<AuthRemoteDataSource>(
        (i) => AuthRemoteDataSourceImpl(
          baseUrl: EnvironmentConfig.authServiceUri,
          dio: i.get<Dio>(),
        ),
      )
      ..addLazySingleton<BiddingRemoteDataSource>(
        (i) => BiddingRemoteDataSourceImpl(
          baseUrl: EnvironmentConfig.driverServiceUri,
          dio: i.get<Dio>(),
        ),
      )
      ..addLazySingleton<TripRemoteDataSource>(
        (i) => TripRemoteDataSourceImpl(
          baseUrl: EnvironmentConfig.driverServiceUri,
          dio: i.get<Dio>(),
        ),
      )
      ..addLazySingleton<TelemetryRemoteDataSource>(
        (i) => TelemetryRemoteDataSourceImpl(
          baseUrl: EnvironmentConfig.driverServiceUri,
          dio: i.get<Dio>(),
        ),
      )
      ..addLazySingleton<PassengerRemoteDataSource>(
        (i) => PassengerRemoteDataSourceImpl(
          baseUrl: EnvironmentConfig.driverServiceUri,
          dio: i.get<Dio>(),
        ),
      )
      ..addLazySingleton<AuthRepository>(
        (i) => AuthRepositoryImpl(remoteDataSource: i.get<AuthRemoteDataSource>()),
      )
      ..addLazySingleton<BiddingRepository>(
        (i) => BiddingRepositoryImpl(remoteDataSource: i.get<BiddingRemoteDataSource>()),
      )
      ..addLazySingleton<TripRepository>(
        (i) => TripRepositoryImpl(remoteDataSource: i.get<TripRemoteDataSource>()),
      )
      ..addLazySingleton<TelemetryRepository>(
        (i) => TelemetryRepositoryImpl(remoteDataSource: i.get<TelemetryRemoteDataSource>()),
      )
      ..addLazySingleton<PassengerRepository>(
        (i) => PassengerRepositoryImpl(remoteDataSource: i.get<PassengerRemoteDataSource>()),
      );
  }

  @override
  List<ModularRoute> get routes => [
    ModuleRoute('/', module: AuthModule()),
    ModuleRoute('/driver/', module: DriverModule()),
  ];
}

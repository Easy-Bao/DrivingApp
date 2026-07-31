import 'package:dio/dio.dart';
import 'package:driver_app/driver_module.dart';
import 'package:driver_app/src/Core/Network/Dioclient.dart';
import 'package:driver_app/src/Core/Network/DriverOperationsClient.dart';
import 'package:driver_app/src/Features/Auth/AuthModule.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/Core/Services/SecureSessionService.dart';
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
          baseUrl: EnvConfig.driverServiceUri,
          sessionService: i.get<SecureSessionService>(),
        ),
      )
      ..addLazySingleton<DriverOperationsClient>(
        (i) => DriverOperationsClient(dio: i.get<Dio>()),
      )
      ..addLazySingleton<AuthRemoteDataSource>(
        (i) => AuthRemoteDataSourceImpl(
          baseUrl: EnvConfig.authServiceUri,
          dio: i.get<Dio>(),
        ),
      )
      ..addLazySingleton<BiddingRemoteDataSource>(
        (i) => BiddingRemoteDataSourceImpl(
          baseUrl: EnvConfig.driverServiceUri,
          dio: i.get<Dio>(),
        ),
      )
      ..addLazySingleton<TripRemoteDataSource>(
        (i) => TripRemoteDataSourceImpl(
          baseUrl: EnvConfig.driverServiceUri,
          dio: i.get<Dio>(),
        ),
      )
      ..addLazySingleton<TelemetryRemoteDataSource>(
        (i) => TelemetryRemoteDataSourceImpl(
          baseUrl: EnvConfig.driverServiceUri,
          dio: i.get<Dio>(),
        ),
      )
      ..addLazySingleton<PassengerRemoteDataSource>(
        (i) => PassengerRemoteDataSourceImpl(
          baseUrl: EnvConfig.driverServiceUri,
          dio: i.get<Dio>(),
        ),
      )
      ..addLazySingleton<AuthRepository>(
        (i) =>
            AuthRepositoryImpl(remoteDataSource: i.get<AuthRemoteDataSource>()),
      )
      ..addLazySingleton<BiddingRepository>(
        (i) => BiddingRepositoryImpl(
          remoteDataSource: i.get<BiddingRemoteDataSource>(),
        ),
      )
      ..addLazySingleton<TripRepository>(
        (i) =>
            TripRepositoryImpl(remoteDataSource: i.get<TripRemoteDataSource>()),
      )
      ..addLazySingleton<TelemetryRepository>(
        (i) => TelemetryRepositoryImpl(
          remoteDataSource: i.get<TelemetryRemoteDataSource>(),
        ),
      )
      ..addLazySingleton<PassengerRepository>(
        (i) => PassengerRepositoryImpl(
          remoteDataSource: i.get<PassengerRemoteDataSource>(),
        ),
      );
  }

  @override
  List<ModularRoute> get routes => [
    ModuleRoute('/', module: AuthModule()),
    ModuleRoute('/driver/', module: DriverModule()),
  ];
}

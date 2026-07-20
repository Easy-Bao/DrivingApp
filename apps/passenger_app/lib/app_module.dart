import 'package:dio/dio.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/passenger_module.dart';
import 'package:passenger_app/src/core/network/dio_client.dart';
import 'package:passenger_app/src/features/auth/auth_module.dart';
import 'package:passenger_services/passenger_services.dart';
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
      ..addLazySingleton<PassengerSessionService>(
        (i) => PassengerSessionService(
          secureSessionService: i.get<SecureSessionService>(),
          prefs: i.get<SharedPreferences>(),
        ),
      )
      ..addLazySingleton<Dio>(
        (i) => DioClient.create(
          baseUrl: EnvironmentConfig.passengerServiceUri,
          sessionService: i.get<SecureSessionService>(),
        ),
      )
      ..addLazySingleton<AuthRemoteDataSource>(
        (i) => AuthRemoteDataSource(
          baseUrl: EnvironmentConfig.passengerServiceUri,
          dio: i.get<Dio>(),
        ),
      )
      ..addLazySingleton<PassengerRemoteDataSource>(
        (i) => PassengerRemoteDataSource(
          baseUrl: EnvironmentConfig.passengerServiceUri,
          sessionService: i.get<SecureSessionService>(),
          dio: i.get<Dio>(),
        ),
      )
      ..addLazySingleton<BiddingRemoteDataSource>(
        (i) => BiddingRemoteDataSource(
          baseUrl: EnvironmentConfig.passengerServiceUri,
          sessionService: i.get<SecureSessionService>(),
          dio: i.get<Dio>(),
        ),
      )
      ..addLazySingleton<AuthRepository>(
        (i) => AuthRepositoryImpl(remoteDataSource: i.get<AuthRemoteDataSource>()),
      )
      ..addLazySingleton<PassengerProfileRepository>(
        (i) => PassengerProfileRepositoryImpl(
          remoteDataSource: i.get<PassengerRemoteDataSource>(),
        ),
      )
      ..addLazySingleton<BiddingRepository>(
        (i) => BiddingRepositoryImpl(
          remoteDataSource: i.get<BiddingRemoteDataSource>(),
        ),
      );
  }

  @override
  List<ModularRoute> get routes => [
    ModuleRoute('/', module: AuthModule()),
    ModuleRoute('/passenger/', module: PassengerModule()),
  ];
}

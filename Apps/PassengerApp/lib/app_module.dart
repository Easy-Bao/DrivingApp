import 'package:dio/dio.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/passenger_module.dart';
import 'package:passenger_app/src/Core/Network/Dioclient.dart';
import 'package:passenger_app/src/Features/Auth/AuthModule.dart';
import 'package:passenger_app/src/Core/Services/Securesessionservice.dart';
import 'package:passenger_app/src/Features/Booking/Data/DataSources/BiddingRemoteDataSource.dart';


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
          baseUrl: EnvConfig.passengerServiceUri,
          sessionService: i.get<SecureSessionService>(),
        ),
      )
      ..addLazySingleton<AuthRemoteDataSource>(
        (i) => AuthRemoteDataSource(
          baseUrl: EnvConfig.authServiceUri,
          dio: i.get<Dio>(),
        ),
      )
      ..addLazySingleton<PassengerRemoteDataSource>(
        (i) => PassengerRemoteDataSource(
          baseUrl: EnvConfig.passengerServiceUri,
          sessionService: i.get<SecureSessionService>(),
          dio: i.get<Dio>(),
        ),
      )
      ..addLazySingleton<BiddingRemoteDataSource>(
        (i) => BiddingRemoteDataSource(
          baseUrl: EnvConfig.passengerServiceUri,
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
      )
      ..addLazySingleton<FareRemoteDataSource>(
        (i) => FareRemoteDataSourceImpl(
          baseUrl: EnvConfig.fareServiceUri,
          dio: i.get<Dio>(),
        ),
      )
      ..addLazySingleton<FareRepository>(
        (i) => FareRepositoryImpl(
          remoteDataSource: i.get<FareRemoteDataSource>(),
        ),
      );
  }

  @override
  List<ModularRoute> get routes => [
    ModuleRoute('/', module: AuthModule()),
    ModuleRoute('/passenger/', module: PassengerModule()),
  ];
}

import 'package:dio/dio.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/PassengerModule.dart';
import 'package:passenger_app/src/Core/Constants/EnvConfig.dart';
import 'package:passenger_app/src/Core/Network/DioClient.dart';
import 'package:passenger_app/src/Core/Services/SecureSessionService.dart';
import 'package:passenger_app/src/Features/Auth/AuthModule.dart';
import 'package:passenger_app/src/Features/Auth/Data/DataSources/AuthRemoteDataSource.dart';
import 'package:passenger_app/src/Features/Booking/Data/DataSources/BiddingRemoteDataSource.dart';
import 'package:passenger_app/src/Features/Booking/Data/DataSources/PassengerRemoteDataSource.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppModule extends Module {
  final SharedPreferences _prefs;

  AppModule({required SharedPreferences prefs}) : _prefs = prefs;

  @override
  void binds(Injector i) {
    i
      ..addSingleton<SharedPreferences>((i) => _prefs)
      ..addLazySingleton<SecureSessionService>((i) => SecureSessionService())
      ..addLazySingleton<Dio>(
        (i) => DioClient.create(
          baseUrl: EnvConfig.passengerServiceUri,
          sessionService: i.get<SecureSessionService>(),
        ),
      )
      ..addLazySingleton<AuthRemoteDataSource>(
        (i) => AuthRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<PassengerRemoteDataSource>(
        (i) => PassengerRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<BiddingRemoteDataSource>(
        (i) => BiddingRemoteDataSourceImpl(i.get<Dio>()),
      );
  }

  @override
  List<ModularRoute> get routes => [
    ModuleRoute('/', module: AuthModule()),
    ModuleRoute('/passenger/', module: PassengerModule()),
  ];
}

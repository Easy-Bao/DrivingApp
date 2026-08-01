import 'package:dio/dio.dart';
import 'package:driver_app/DriverModule.dart';
import 'package:driver_app/src/Core/Constants/EnvConfig.dart';
import 'package:driver_app/src/Core/Network/DioClient.dart';
import 'package:driver_app/src/Core/Services/SecureSessionService.dart';
import 'package:driver_app/src/Features/Auth/AuthModule.dart';
import 'package:driver_app/src/Features/Auth/Data/DataSources/AuthRemoteDataSource.dart';
import 'package:driver_app/src/Features/Auth/Data/Repositories/AuthRepository.dart';
import 'package:driver_app/src/Features/Trip/Data/DataSources/BiddingRemoteDataSource.dart';
import 'package:driver_app/src/Features/Trip/Data/DataSources/PassengerRemoteDataSource.dart';
import 'package:driver_app/src/Features/Trip/Data/DataSources/TelemetryRemoteDataSource.dart';
import 'package:driver_app/src/Features/Trip/Data/DataSources/TripRemoteDataSource.dart';
import 'package:go_router_modular/go_router_modular.dart';
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
          baseUrl: EnvConfig.driverServiceUri,
          sessionService: i.get<SecureSessionService>(),
        ),
      )
      ..addLazySingleton<AuthRemoteDataSource>(
        (i) => AuthRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<BiddingRemoteDataSource>(
        (i) => BiddingRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<TripRemoteDataSource>(
        (i) => TripRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<TelemetryRemoteDataSource>(
        (i) => TelemetryRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<PassengerRemoteDataSource>(
        (i) => PassengerRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<AuthRepository>(
        (i) => AuthRepository(
          remoteDataSource: i.get<AuthRemoteDataSource>(),
          secureSessionService: i.get<SecureSessionService>(),
        ),
      );
  }

  @override
  List<ModularRoute> get routes => [
    ModuleRoute('/', module: AuthModule()),
    ModuleRoute('/driver/', module: DriverModule()),
  ];
}

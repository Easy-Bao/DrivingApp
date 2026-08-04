import 'package:dio/dio.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/passenger_module.dart';
import 'package:passenger_app/src/core/constants/env_config.dart';
import 'package:passenger_app/src/core/network/dio_client.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/core/storage/secure_storage.dart';
import 'package:passenger_app/src/features/auth/auth_module.dart';
import 'package:passenger_app/src/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:passenger_app/src/features/booking/data/data_sources/bidding_remote_data_source.dart';
import 'package:passenger_app/src/features/booking/data/data_sources/passenger_remote_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppModule extends Module {
  final SharedPreferences _prefs;

  AppModule({required SharedPreferences prefs}) : _prefs = prefs;

  @override
  void binds(Injector i) {
    i
      ..addSingleton<SharedPreferences>((i) => _prefs)
      ..addLazySingleton<SecureSessionService>((i) => SecureSessionService())
      ..addLazySingleton<SecureStorage>(
        (i) => SecureStorage(i.get<SecureSessionService>()),
      )
      ..addLazySingleton<Dio>(
        (i) => DioClient.create(
          baseUrl: EnvConfig.apiBaseUri,
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

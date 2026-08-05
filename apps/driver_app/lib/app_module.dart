import 'package:dio/dio.dart';
import 'package:driver_app/driver_module.dart';
import 'package:driver_app/src/core/constants/env_config.dart';
import 'package:driver_app/src/core/network/dio_client.dart';
import 'package:driver_app/src/core/services/background_telemetry_service.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/core/storage/secure_storage.dart';
import 'package:driver_app/src/features/auth/auth_module.dart';
import 'package:driver_app/src/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:driver_app/src/features/auth/data/repositories/auth_repository.dart';
import 'package:driver_app/src/features/trip/data/data_sources/bidding_remote_data_source.dart';
import 'package:driver_app/src/features/trip/data/data_sources/passenger_remote_data_source.dart';
import 'package:driver_app/src/features/trip/data/data_sources/telemetry_remote_data_source.dart';
import 'package:driver_app/src/features/trip/data/data_sources/trip_remote_data_source.dart';
import 'package:driver_app/src/features/chat/data/data_sources/chat_room_remote_data_source.dart';
import 'package:driver_app/src/features/home/data/data_sources/driver_remote_data_source.dart';
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
      ..addLazySingleton<BackgroundTelemetryService>(
        (i) => BackgroundTelemetryService(apiBaseUri: EnvConfig.apiBaseUri),
      )
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
      ..addLazySingleton<ChatRoomRemoteDataSource>(
        (i) => ChatRoomRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<DriverRemoteDataSource>(
        (i) => DriverRemoteDataSourceImpl(i.get<Dio>()),
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

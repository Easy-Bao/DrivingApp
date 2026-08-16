import 'package:dio/dio.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/passenger_module.dart';
import 'package:passenger_app/src/core/constants/env_config.dart';
import 'package:passenger_app/src/core/network/dio_client.dart';
import 'package:passenger_app/src/core/routing/app_routes.dart';
import 'package:passenger_app/src/core/services/background_telemetry_service.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/core/storage/secure_storage.dart';
import 'package:passenger_app/src/features/auth/auth_module.dart';
import 'package:passenger_app/src/features/auth/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:passenger_app/src/features/auth/data/repositories/session_repository_impl.dart';
import 'package:passenger_app/src/features/auth/domain/repositories/session_repository.dart';
import 'package:passenger_app/src/features/location/bloc/location_access/location_access_cubit.dart';
import 'package:passenger_app/src/features/location/data/repositories/location_access_repository.dart';
import 'package:passenger_app/src/features/location/domain/repositories/i_location_access_repository.dart';
import 'package:passenger_app/src/features/trip/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:passenger_app/src/features/trip/data/datasources/bidding_remote_data_source.dart';
import 'package:passenger_app/src/features/trip/data/datasources/passenger_remote_data_source.dart';
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
      ..addLazySingleton<SessionRepository>(
        (i) => SessionRepositoryImpl(
          secureSessionService: i.get<SecureSessionService>(),
          preferences: i.get<SharedPreferences>(),
        ),
      )
      ..addLazySingleton<SessionBloc>(
        (i) => SessionBloc(sessionRepository: i.get<SessionRepository>()),
      )
      ..addLazySingleton<ILocationAccessRepository>(
        (_) => LocationAccessRepository(),
      )
      ..addLazySingleton<LocationAccessCubit>(
        (i) =>
            LocationAccessCubit(repository: i.get<ILocationAccessRepository>()),
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
      )
      // AppWidget provides this state before the passenger route module is active.
      ..addLazySingleton<BookingDraftCubit>((_) => BookingDraftCubit());
  }

  @override
  List<ModularRoute> get routes => [
    ModuleRoute(AppRoutes.authModulePath, module: AuthModule()),
    ModuleRoute(AppRoutes.passengerModulePath, module: PassengerModule()),
  ];
}

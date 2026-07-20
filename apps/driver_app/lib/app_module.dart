import 'package:driver_app/driver_module.dart';
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
      ..addLazySingleton<AuthApiService>(
        (i) => AuthApiService(baseUrl: EnvironmentConfig.driverServiceUri),
      )
      ..addLazySingleton<BiddingApiService>(
        (i) => BiddingApiService(baseUrl: EnvironmentConfig.driverServiceUri),
      )
      ..addLazySingleton<TripApiService>(
        (i) => TripApiService(baseUrl: EnvironmentConfig.driverServiceUri),
      )
      ..addLazySingleton<TelemetryApiService>(
        (i) => TelemetryApiService(baseUrl: EnvironmentConfig.driverServiceUri),
      )
      ..addLazySingleton<PassengerApiService>(
        (i) => PassengerApiService(baseUrl: EnvironmentConfig.driverServiceUri),
      );
  }

  @override
  List<ModularRoute> get routes => [
    ModuleRoute('/', module: AuthModule()),
    ModuleRoute('/driver/', module: DriverModule()),
  ];
}

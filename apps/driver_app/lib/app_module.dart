import 'package:driver_app/src/core/config/environment_config.dart';
import 'package:driver_app/src/features/auth/auth_module.dart';
import 'package:driver_app/src/features/driver_dispatch/driver_dispatch_module.dart';
import 'package:driver_services/driver_services.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:session_service/session_service.dart';

class AppModule extends Module {
  @override
  void binds(Injector i) {
    i
      ..addLazySingleton<SecureSessionService>((i) => SecureSessionService())
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
    ModuleRoute('/driver/', module: DriverDispatchModule()),
  ];
}


import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/config/environment_config.dart';
import 'package:passenger_app/src/features/auth/auth_module.dart';
import 'package:passenger_app/src/features/trip_booking/passenger.module.dart';
import 'package:passenger_services/passenger_services.dart';
import 'package:session_service/session_service.dart';

class AppModule extends Module {
  @override
  void binds(Injector i) {
    i
      ..addLazySingleton<SecureSessionService>((i) => SecureSessionService())
      ..addLazySingleton<PassengerApiService>(
        (i) => PassengerApiService(
          baseUrl: EnvironmentConfig.passengerServiceUri,
          sessionService: i.get<SecureSessionService>(),
        ),
      );
  }

  @override
  List<ModularRoute> get routes => [
    ModuleRoute('/', module: AuthModule()),
    ModuleRoute('/passenger/', module: PassengerModule()),
  ];
}

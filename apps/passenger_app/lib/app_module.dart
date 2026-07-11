import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/auth/auth_module.dart';
import 'package:passenger_app/src/features/trip_booking/passenger.module.dart';

class AppModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ModuleRoute('/', module: AuthModule()),
    ModuleRoute('/passenger/', module: PassengerModule()),
  ];
}

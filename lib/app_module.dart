import 'package:BaoRide/features/auth/auth_module.dart';
import 'package:BaoRide/features/driver/driver.module.dart';
import 'package:BaoRide/features/passenger/passenger.module.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ModuleRoute('/', module: AuthModule()),
    ModuleRoute("/passenger/", module: PassengerModule()),
    ModuleRoute("/driver/", module: DriverModule()),
  ];
}

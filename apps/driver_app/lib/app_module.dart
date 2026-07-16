import 'package:driver_app/src/features/auth/auth_module.dart';
import 'package:driver_app/src/features/driver_dispatch/driver_dispatch_module.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AppModule extends Module {
  @override
  List<ModularRoute> get routes => [
    ModuleRoute('/', module: AuthModule()),
    ModuleRoute('/driver/', module: DriverDispatchModule()),
  ];
}


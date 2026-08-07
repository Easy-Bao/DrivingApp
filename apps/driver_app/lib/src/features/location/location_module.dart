import 'package:driver_app/src/features/location/location_routes.dart';
import 'package:driver_app/src/features/location/view/driver_location_gate_page.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_ui/shared_ui.dart';

class DriverLocationModule {
  DriverLocationModule._();

  static final List<ModularRoute> routes = [
    ChildRoute(
      name: DriverLocationRoutes.gate,
      DriverLocationRoutes.gatePath,
      child: (context, GoRouterState state) => const DriverLocationGatePage(),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}

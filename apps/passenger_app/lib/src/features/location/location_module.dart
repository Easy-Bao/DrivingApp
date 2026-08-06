import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/location/location_routes.dart';
import 'package:passenger_app/src/features/location/view/location_gate_page.dart';
import 'package:shared_ui/shared_ui.dart';

class LocationModule {
  LocationModule._();

  static final List<ModularRoute> routes = [
    ChildRoute(
      name: LocationRoutes.gate,
      'location-gate',
      child: (context, GoRouterState state) => const LocationGatePage(),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}

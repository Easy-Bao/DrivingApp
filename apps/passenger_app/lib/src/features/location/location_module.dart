import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/location/location_routes.dart';
import 'package:passenger_app/src/features/location/view/location_country_page.dart';
import 'package:passenger_app/src/features/location/view/location_gate_page.dart';
import 'package:passenger_app/src/features/location/view/location_search_page.dart';
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
    ChildRoute(
      name: LocationRoutes.country,
      'location/country',
      child: (context, GoRouterState state) => const LocationCountryPage(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: LocationRoutes.search,
      'location/search',
      child: (context, GoRouterState state) => LocationSearchPage(
        country: state.uri.queryParameters['country'] ?? 'Philippines',
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];
}

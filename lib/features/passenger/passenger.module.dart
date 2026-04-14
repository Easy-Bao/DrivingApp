import 'package:BaoRide/features/passenger/modules/home_module.dart';
import 'package:BaoRide/features/passenger/presentation/views/passenger_account.dart';
import 'package:BaoRide/features/passenger/presentation/views/passenger_favorites.dart';
import 'package:BaoRide/features/passenger/presentation/views/passenger_order.dart';
import 'package:BaoRide/shared/widgets/navigationbar/passenger_tab.dart';
import 'package:go_router_modular/go_router_modular.dart';

class PassengerModule extends Module {
  @override
  List<ModularRoute> get routes => <ModularRoute>[
    ShellModularRoute(
      builder: (context, GoRouterState state, child) =>
          PassengerShellLayout(child: child),
      routes: [
        ...HomeRoutes.shellRoutes,
        ChildRoute(
          name: "PassengerOrder",
          "order",
          child: (context, GoRouterState state) => PassengerOrderScreen(),
        ),
        ChildRoute(
          name: "PassengerFavorites",
          "favorites",
          child: (context, GoRouterState state) => PassengerFavoritesScreen(),
        ),
        ChildRoute(
          name: "PassengerAccount",
          "account",
          child: (context, GoRouterState state) => PassengerAccountScreen(),
        ),
      ],
    ),
  ];
}

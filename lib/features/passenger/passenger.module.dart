import 'package:BaoRide/features/passenger/modules/activity_module.dart';
import 'package:BaoRide/features/passenger/modules/home_module.dart';
import 'package:BaoRide/features/passenger/presentation/views/passenger_account.dart';
import 'package:BaoRide/features/passenger/presentation/views/passenger_favorites.dart';
import 'package:BaoRide/shared/widgets/navigationbar/passenger_tab.dart';
import 'package:go_router_modular/go_router_modular.dart';

class PassengerModule extends Module {
  final homeRoutes = [...HomeModule.shellRoutes, ...HomeModule.routes];
  final activityRoutes = [...ActivityModule.shellRoutes];

  @override
  List<ModularRoute> get routes => <ModularRoute>[
    ShellModularRoute(
      builder: (context, GoRouterState state, child) =>
          PassengerShellLayout(child: child),
      routes: [
        ...homeRoutes,
        ...activityRoutes,
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

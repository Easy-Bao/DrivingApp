import 'package:BaoRide/features/passenger/modules/account_module.dart';
import 'package:BaoRide/features/passenger/modules/activity_module.dart';
import 'package:BaoRide/features/passenger/modules/home_module.dart';
import 'package:BaoRide/features/passenger/presentation/views/passenger_account.dart';
import 'package:BaoRide/shared/widgets/navigationbar/passenger_tab.dart';
import 'package:go_router_modular/go_router_modular.dart';

class PassengerModule extends Module {
  final homeRoutes = [...HomeModule.shellRoutes];
  final homeRoutesScreen = [...HomeModule.routes];

  final activityRoutes = [...ActivityModule.shellRoutes];
  final activityRoutesScreen = [...ActivityModule.routes];

  final accountRoutesScreen = [...AccountModule.routes];

  static List<ModularRoute> get route => <ModularRoute>[...HomeModule.routes];

  @override
  List<ModularRoute> get routes => <ModularRoute>[
    // Independent Screen
    ...activityRoutesScreen,
    ...homeRoutesScreen,
    ...accountRoutesScreen,
    ShellModularRoute(
      builder: (context, GoRouterState state, child) =>
          PassengerShellLayout(child: child),
      routes: [
        ...homeRoutes,
        ...activityRoutes,
        ChildRoute(
          name: 'PassengerAccount',
          'account',
          child: (context, GoRouterState state) => PassengerAccountScreen(),
        ),
      ],
    ),
  ];
}

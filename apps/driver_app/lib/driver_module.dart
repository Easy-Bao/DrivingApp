import 'dart:async';

import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/features/activity/activity_module.dart';
import 'package:driver_app/src/features/chat/chat_module.dart';
import 'package:driver_app/src/features/home/home_module.dart';
import 'package:driver_app/src/features/help_center/help_center_module.dart';
import 'package:driver_app/src/shared/widgets/navigationbar/driver_navigation_shell.dart';
import 'package:driver_app/src/features/profile/profile_module.dart';
import 'package:driver_app/src/features/location/location_module.dart';
import 'package:driver_app/src/features/settings/settings_module.dart';
import 'package:driver_app/src/features/trip/trip_module.dart';

class DriverModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    ActivityModule.binds(i);
    TripModule.binds(i);
    HomeModule.binds(i);
    ProfileModule.binds(i);

    i.addLazySingleton<DriverTabNavigationCoordinator>(
      (_) => DriverTabNavigationCoordinator(),
    );
  }

  @override
  List<ModularRoute> get routes => <ModularRoute>[
    ...HomeModule.routes,
    ...TripModule.routes,
    ...ChatModule.routes,
    ...ActivityModule.routes,
    ...ProfileModule.routes,
    ...DriverLocationModule.routes,
    ...DriverSettingsModule.routes,
    ...DriverHelpCenterModule.routes,

    StatefulShellModularRoute(
      builder: (context, GoRouterState state, navigationShell) =>
          DriverShellLayout(
            navigationShell: navigationShell,
            navigationCoordinator:
                Modular.get<DriverTabNavigationCoordinator>(),
          ),
      navigatorContainerBuilder: (context, navigationShell, children) =>
          DriverTabBranchContainer(
            navigationShell: navigationShell,
            onNavigationSettled:
                Modular.get<DriverTabNavigationCoordinator>().commit,
            onPagePositionChanged: Modular.get<DriverTabNavigationCoordinator>()
                .updatePagePosition,
            children: children,
          ),
      branches: [
        ModularBranch(routes: HomeModule.shellRoutes),
        ModularBranch(routes: ActivityModule.shellRoutes),
        ModularBranch(routes: ProfileModule.earningsShellRoutes),
        ModularBranch(routes: ProfileModule.accountShellRoutes),
      ],
    ),
  ];
}

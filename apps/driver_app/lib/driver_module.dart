import 'dart:async';

import 'package:maps/maps.dart';
import 'package:driver_app/src/infrastructure/telemetry/driver_background_telemetry.dart';
import 'package:driver_app/src/features/auth/domain/services/driver_logout_coordinator.dart';
import 'package:driver_app/src/infrastructure/session/driver_session_store.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/features/activity/activity_module.dart';
import 'package:driver_app/src/features/chat/chat_module.dart';
import 'package:driver_app/src/features/home/home_module.dart';
import 'package:driver_app/src/features/home/presentation/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver_app/src/features/help_center/help_center_module.dart';
import 'package:driver_app/src/app/navigation/driver_navigation_shell.dart';
import 'package:driver_app/src/features/profile/profile_module.dart';
import 'package:driver_app/src/features/settings/settings_module.dart';
import 'package:driver_app/src/features/active_ride/active_ride_module.dart';

class DriverModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    ActivityModule.binds(i);
    ActiveRideModule.binds(i);
    ChatModule.binds(i);
    HomeModule.binds(i);
    ProfileModule.binds(i);

    i
      ..addLazySingleton<DriverLogoutCoordinator>(
        (i) => DriverLogoutCoordinator(
          forceOffline: () async {
            final position = LocationService.lastPosition;
            await i.get<DashboardCubit>().forceOffline(
              lat: position?.latitude ?? 0,
              lng: position?.longitude ?? 0,
            );
          },
          stopTelemetry: () => i.get<DriverBackgroundTelemetry>().stop(),
          clearSession: () => i.get<DriverSessionStore>().clearSession(),
        ),
      )
      ..addLazySingleton<DriverTabNavigationCoordinator>(
        (_) => DriverTabNavigationCoordinator(),
      );
  }

  @override
  List<ModularRoute> get routes => <ModularRoute>[
    ...HomeModule.routes,
    ...ActiveRideModule.routes,
    ...ChatModule.routes,
    ...ActivityModule.routes,
    ...ProfileModule.routes,
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
        ModularBranch(routes: ActivityModule.earningsShellRoutes),
        ModularBranch(routes: ProfileModule.accountShellRoutes),
      ],
    ),
  ];
}

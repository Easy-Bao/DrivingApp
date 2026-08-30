import 'dart:async';

import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/constants/env_config.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/activity/activity_module.dart';
import 'package:passenger_app/src/features/chat/chat_module.dart';
import 'package:passenger_app/src/features/driver_profile/driver_profile_module.dart';
import 'package:passenger_app/src/features/home/home_module.dart';
import 'package:passenger_app/src/features/inbox/bloc/inbox/inbox_cubit.dart';
import 'package:passenger_app/src/features/inbox/inbox_module.dart';
import 'package:passenger_app/src/features/profile/profile_module.dart';
import 'package:passenger_app/src/features/saved_places/saved_places_module.dart';
import 'package:passenger_app/src/features/settings/settings_module.dart';
import 'package:passenger_app/src/features/trip/trip_module.dart';
import 'package:passenger_app/src/shared/widgets/navigationbar/passenger_navigation_shell.dart';
import 'package:shared_core/shared_core.dart';

class PassengerModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    ActivityModule.binds(i);
    DriverProfileModule.binds(i);
    HomeModule.binds(i);
    InboxModule.binds(i);
    ProfileModule.binds(i);
    SavedPlacesModule.binds(i);
    TripModule.binds(i);

    i
      ..addLazySingleton<PassengerTabNavigationCoordinator>(
        (_) => PassengerTabNavigationCoordinator(),
      )
      ..addLazySingleton<RealtimeWebSocketClient>(
        (i) => RealtimeWebSocketClient(
          uri: EnvConfig.webSocketBaseUri.replace(path: '/api/v1/realtime/ws'),
          tokenProvider: i.get<SecureSessionService>().readToken,
        ),
      );
  }

  @override
  List<ModularRoute> get routes => <ModularRoute>[
    ...ActivityModule.routes,
    ...HomeModule.routes,
    ...TripModule.routes,
    ...SavedPlacesModule.routes,
    ...ChatModule.routes,
    ...ProfileModule.routes,
    ...SettingsModule.routes,

    StatefulShellModularRoute(
      builder: (context, GoRouterState state, navigationShell) =>
          PassengerShellLayout(
            inboxCubit: Modular.get<InboxCubit>(),
            realtimeClient: Modular.get<RealtimeWebSocketClient>(),
            lifecycleCoordinator: Modular.get<AppLifecycleCoordinator>(),
            navigationCoordinator:
                Modular.get<PassengerTabNavigationCoordinator>(),
            navigationShell: navigationShell,
          ),
      navigatorContainerBuilder: (context, navigationShell, children) =>
          PassengerTabBranchContainer(
            navigationShell: navigationShell,
            onNavigationSettled:
                Modular.get<PassengerTabNavigationCoordinator>().commit,
            onPagePositionChanged:
                Modular.get<PassengerTabNavigationCoordinator>()
                    .updatePagePosition,
            children: children,
          ),
      branches: [
        ModularBranch(routes: HomeModule.shellRoutes),
        ModularBranch(routes: ActivityModule.shellRoutes),
        ModularBranch(routes: InboxModule.shellRoutes),
        ModularBranch(routes: ProfileModule.shellRoutes),
      ],
    ),
  ];
}

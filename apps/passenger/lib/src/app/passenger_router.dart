import 'dart:async';

import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/app/navigation/passenger_navigation_shell.dart';
import 'package:passenger/src/features/active_ride/active_ride_module.dart';
import 'package:passenger/src/features/booking/booking_module.dart';
import 'package:passenger/src/features/chat/chat_module.dart';
import 'package:passenger/src/features/driver_profile/driver_profile_module.dart';
import 'package:passenger/src/features/home/home_module.dart';
import 'package:passenger/src/features/inbox/inbox_module.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox/inbox_cubit.dart';
import 'package:passenger/src/features/profile/profile_module.dart';
import 'package:passenger/src/features/ride_history/ride_history_module.dart';
import 'package:passenger/src/features/saved_places/saved_places_module.dart';
import 'package:passenger/src/features/settings/settings_module.dart';
import 'package:passenger/src/infrastructure/config/passenger_env_config.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';

class PassengerRouter extends Module {
  @override
  List<ModularRoute> get routes => <ModularRoute>[
    ...RideHistoryModule.routes,
    ...HomeModule.routes,
    ...ActiveRideModule.routes,
    ...BookingModule.routes,
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
        ModularBranch(routes: RideHistoryModule.shellRoutes),
        ModularBranch(routes: InboxModule.shellRoutes),
        ModularBranch(routes: ProfileModule.shellRoutes),
      ],
    ),
  ];

  @override
  FutureOr<void> binds(Injector i) {
    RideHistoryModule.binds(i);
    ChatModule.binds(i);
    DriverProfileModule.binds(i);
    HomeModule.binds(i);
    InboxModule.binds(i);
    ProfileModule.binds(i);
    SavedPlacesModule.binds(i);
    ActiveRideModule.binds(i);
    BookingModule.binds(i);

    i
      ..addLazySingleton<PassengerTabNavigationCoordinator>(
        (_) => PassengerTabNavigationCoordinator(),
      )
      ..addLazySingleton<RealtimeWebSocketClient>(
        (i) => RealtimeWebSocketClient(
          uri: PassengerEnvConfig.webSocketBaseUri.replace(
            path: '/api/v1/realtime/ws',
          ),
          tokenProvider: i.get<PassengerSessionStore>().readToken,
        ),
      );
  }
}

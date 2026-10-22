import 'dart:async';

import 'package:design_system/design_system.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/app/navigation/navigation_shell.dart';
import 'package:passenger/src/core/config/env_config.dart';
import 'package:passenger/src/core/location/live_map_bloc.dart';
import 'package:passenger/src/features/active_ride/active_ride_module.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/booking/booking_module.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger/src/features/chat/chat_module.dart';
import 'package:passenger/src/features/driver_profile/driver_profile_module.dart';
import 'package:passenger/src/features/home/home_module.dart';
import 'package:passenger/src/features/inbox/inbox_module.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox_cubit.dart';
import 'package:passenger/src/features/profile/profile_module.dart';
import 'package:passenger/src/features/ride_history/ride_history_module.dart';
import 'package:passenger/src/features/saved_places/saved_places_module.dart';
import 'package:passenger/src/features/settings/settings_module.dart';

class AppRouter extends Module {
  @override
  List<ModularRoute> get routes => <ModularRoute>[
    ...RideHistoryModule.routes,
    ...HomeModule.routes,
    ...ActiveRideModule.routes(
      onRideTerminated: () {
        Modular.get<BookingBloc>().add(const ResetBookingEvent());
      },
    ),
    ...BookingModule.routes,
    ...SavedPlacesModule.routes,
    ...ChatModule.routes,
    ...ProfileModule.routes,
    ...SettingsModule.routes,

    StatefulShellModularRoute(
      builder: (context, GoRouterState state, navigationShell) => ShellLayout(
        inboxCubit: Modular.get<InboxCubit>(),
        bookingStates: Modular.get<BookingBloc>().stream,
        realtimeClient: Modular.get<RealtimeWebSocketClient>(),
        lifecycleCoordinator: Modular.get<AppLifecycleCoordinator>(),
        navigationCoordinator: Modular.get<TabNavigationCoordinator>(),
        navigationShell: navigationShell,
      ),
      navigatorContainerBuilder: (context, navigationShell, children) =>
          BlocSelector<SessionBloc, SessionState, bool>(
            selector: (state) => state.isAuthenticated,
            builder: (context, isAuthenticated) => TabBranchContainer(
              navigationShell: navigationShell,
              allowUserNavigation: isAuthenticated,
              onNavigationSettled:
                  Modular.get<TabNavigationCoordinator>().commit,
              onPagePositionChanged:
                  Modular.get<TabNavigationCoordinator>().updatePagePosition,
              children: children,
            ),
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
      ..addFactory<LiveMapBloc>((_) => LiveMapBloc())
      ..addLazySingleton<TabNavigationCoordinator>(
        (_) => TabNavigationCoordinator(),
      )
      ..addLazySingleton<RealtimeWebSocketClient>(
        (i) => RealtimeWebSocketClient(
          uri: EnvConfig.webSocketBaseUri.replace(path: '/api/v1/realtime/ws'),
          tokenProvider: i.get<RefreshableTokenProvider>().getToken,
          refreshToken: i.get<RefreshableTokenProvider>().refreshAccessToken,
          networkAvailability: i.get<NetworkAvailabilityCoordinator>(),
        ),
      );
  }
}

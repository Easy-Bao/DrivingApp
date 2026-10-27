import 'package:design_system/design_system.dart';

import 'dart:async';

import 'package:maps/maps.dart';
import 'package:driver/src/infrastructure/telemetry/driver_background_telemetry.dart';
import 'package:driver/src/infrastructure/telemetry/driver_location_spool.dart';
import 'package:driver/src/features/auth/domain/services/driver_logout_coordinator.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver/src/features/chat/chat_module.dart';
import 'package:driver/src/features/dashboard/dashboard_module.dart';
import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver/src/features/help_center/help_center_module.dart';
import 'package:driver/src/app/navigation/driver_navigation_shell.dart';
import 'package:driver/src/features/profile/profile_module.dart';
import 'package:driver/src/features/settings/settings_module.dart';
import 'package:driver/src/features/active_ride/active_ride_module.dart';
import 'package:driver/src/features/active_ride/domain/services/ride_completion_handler.dart';
import 'package:driver/src/features/earnings/earnings_module.dart';
import 'package:driver/src/features/performance/performance_module.dart';
import 'package:driver/src/features/ride_history/ride_history_module.dart';

class AppRouter extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    ActiveRideModule.binds(i);
    ChatModule.binds(i);
    EarningsModule.binds(i);
    PerformanceModule.binds(i);
    RideHistoryModule.binds(i);
    DashboardModule.binds(i);
    ProfileModule.binds(i);

    i
      ..addLazySingleton<RideCompletionHandler>(
        (i) => _DashboardRideCompletionHandler(
          dashboardCubit: i.get<DashboardCubit>(),
        ),
      )
      ..addLazySingleton<LogoutCoordinator>(
        (i) => LogoutCoordinator(
          forceOffline: () async {
            final position = LocationService.lastPosition;
            await i.get<DashboardCubit>().forceOffline(
              lat: position?.latitude ?? 0,
              lng: position?.longitude ?? 0,
            );
          },
          stopTelemetry: () => i.get<BackgroundTelemetry>().stop(),
          clearLocationSpool: () => i.get<LocationSpool>().clear(),
          clearSession: () => i.get<SessionStore>().clearSession(),
        ),
      )
      ..addLazySingleton<TabNavigationCoordinator>(
        (_) => TabNavigationCoordinator(),
      );
  }

  @override
  List<ModularRoute> get routes => <ModularRoute>[
    ...DashboardModule.routes,
    ...ActiveRideModule.routes,
    ...ChatModule.routes,
    ...PerformanceModule.routes,
    ...RideHistoryModule.routes,
    ...ProfileModule.routes,
    ...SettingsModule.routes,
    ...HelpCenterModule.routes,

    StatefulShellModularRoute(
      builder: (context, GoRouterState state, navigationShell) => ShellLayout(
        navigationShell: navigationShell,
        navigationCoordinator: Modular.get<TabNavigationCoordinator>(),
      ),
      navigatorContainerBuilder: (context, navigationShell, children) =>
          TabBranchContainer(
            navigationShell: navigationShell,
            onNavigationSettled: Modular.get<TabNavigationCoordinator>().commit,
            onPagePositionChanged:
                Modular.get<TabNavigationCoordinator>().updatePagePosition,
            children: children,
          ),
      branches: [
        ModularBranch(routes: DashboardModule.shellRoutes),
        ModularBranch(routes: RideHistoryModule.shellRoutes),
        ModularBranch(routes: EarningsModule.shellRoutes),
        ModularBranch(routes: ProfileModule.accountShellRoutes),
      ],
    ),
  ];
}

final class _DashboardRideCompletionHandler implements RideCompletionHandler {
  const _DashboardRideCompletionHandler({required this.dashboardCubit});

  final DashboardCubit dashboardCubit;

  @override
  Future<void> afterRideCompleted({required String rideId}) async {
    dashboardCubit.removeActiveRide(rideId);
    if (dashboardCubit.state.isOnline) {
      final position =
          LocationService.lastPosition ??
          await LocationService.getCurrentPosition();
      if (position != null) {
        await dashboardCubit.refreshOnlinePresence(
          lat: position.latitude,
          lng: position.longitude,
        );
      }
      await dashboardCubit.loadDispatchSnapshot(silent: true, force: true);
    }
    await dashboardCubit.loadStats();
  }
}

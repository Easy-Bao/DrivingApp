import 'dart:async';

import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/features/activity/activity_module.dart';
import 'package:driver_app/src/features/activity/data/repositories/driver_activity_repository.dart';
import 'package:driver_app/src/features/activity/domain/repositories/i_driver_activity_repository.dart';
import 'package:driver_app/src/features/chat/chat_module.dart';
import 'package:driver_app/src/features/home/home_module.dart';
import 'package:driver_app/src/features/home/data/repositories/dashboard_repository.dart';
import 'package:driver_app/src/features/home/data/datasources/driver_remote_data_source.dart';
import 'package:driver_app/src/features/home/domain/repositories/i_dashboard_repository.dart';
import 'package:driver_app/src/features/home/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver_app/src/shared/widgets/navigationbar/driver_navigation_shell.dart';
import 'package:driver_app/src/features/profile/profile_module.dart';
import 'package:driver_app/src/features/location/location_module.dart';
import 'package:driver_app/src/features/trip/data/repositories/ride_repository.dart';
import 'package:driver_app/src/features/trip/domain/repositories/i_ride_repository.dart';
import 'package:driver_app/src/features/trip/bloc/live_map/live_map_bloc.dart';
import 'package:driver_app/src/features/trip/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/core/services/background_telemetry_service.dart';
import 'package:driver_app/src/features/trip/trip_module.dart';
import 'package:driver_app/src/features/trip/data/datasources/bidding_remote_data_source.dart';
import 'package:driver_app/src/features/trip/data/datasources/telemetry_remote_data_source.dart';
import 'package:driver_app/src/features/trip/data/datasources/trip_remote_data_source.dart';

class DriverModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i
      ..addLazySingleton<IDashboardRepository>(
        (i) => DashboardRepository(
          remoteDataSource: i.get<TripRemoteDataSource>(),
          driverRemoteDataSource: i.get<DriverRemoteDataSource>(),
          telemetryRemoteDataSource: i.get<TelemetryRemoteDataSource>(),
          sessionService: i.get<SecureSessionService>(),
          backgroundTelemetryService: i.get<BackgroundTelemetryService>(),
        ),
      )
      ..addLazySingleton<IRideRepository>(
        (i) =>
            RideRepository(remoteDataSource: i.get<BiddingRemoteDataSource>()),
      )
      ..addLazySingleton<IDriverActivityRepository>(
        (i) => DriverActivityRepository(
          remoteDataSource: i.get<TripRemoteDataSource>(),
        ),
      )
      ..addLazySingleton<DashboardCubit>(
        (i) => DashboardCubit(repository: i.get<IDashboardRepository>()),
      )
      ..addLazySingleton<DriverTabNavigationCoordinator>(
        (_) => DriverTabNavigationCoordinator(),
      )
      ..addFactory<LiveMapBloc>(
        (i) => LiveMapBloc(
          telemetryDataSource: i.get<TelemetryRemoteDataSource>(),
        ),
      )
      ..addFactory<RideFlowCubit>(
        (i) => RideFlowCubit(
          tripRemoteDataSource: i.get<TripRemoteDataSource>(),
          sessionService: i.get<SecureSessionService>(),
        ),
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

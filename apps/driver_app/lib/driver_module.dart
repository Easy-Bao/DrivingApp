import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/features/activity/activity_module.dart';
import 'package:driver_app/src/features/activity/data/repositories/driver_activity_repository_impl.dart';
import 'package:driver_app/src/features/activity/domain/repositories/driver_activity_repository.dart';
import 'package:driver_app/src/features/chat/chat_module.dart';
import 'package:driver_app/src/features/home/home_module.dart';
import 'package:driver_app/src/features/home/data/repositories/dashboard_repository_impl.dart';
import 'package:driver_app/src/features/home/presentation/bloc/dashboard_cubit.dart';
import 'package:driver_app/src/features/home/presentation/widgets/driver_tab.dart';
import 'package:driver_app/src/features/profile/profile_module.dart';
import 'package:driver_app/src/features/trip/data/repositories/ride_repository_impl.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver_app/src/features/trip/trip_module.dart';
import 'package:driver_services/driver_services.dart';
import 'package:session_service/session_service.dart';

class DriverModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i
      ..addLazySingleton<DashboardRepository>(
        (i) => DashboardRepositoryImpl(
          remoteDataSource: i.get<TripRemoteDataSource>(),
          sessionService: i.get<SecureSessionService>(),
        ),
      )
      ..addLazySingleton<RideRepository>(
        (i) => RideRepositoryImpl(remoteDataSource: i.get<BiddingRemoteDataSource>()),
      )
      ..addLazySingleton<DriverActivityRepository>(
        (i) =>
            DriverActivityRepositoryImpl(remoteDataSource: i.get<TripRemoteDataSource>()),
      )
      ..addFactory<DashboardCubit>(
        (i) => DashboardCubit(repository: i.get<DashboardRepository>()),
      )
      ..addFactory<LiveMapBloc>(
        (i) => LiveMapBloc(
          telemetryDataSource: i.get<TelemetryRemoteDataSource>(),
          sessionService: i.get<SecureSessionService>(),
        ),
      )
      ..addFactory<RideFlowCubit>(
        (i) => RideFlowCubit(
          repository: i.get<RideRepository>(),
          tripRemoteDataSource: i.get<TripRemoteDataSource>(),
          sessionService: i.get<DriverSessionService>(),
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

    ShellModularRoute(
      builder: (context, GoRouterState state, child) =>
          DriverShellLayout(child: child),
      routes: [...HomeModule.shellRoutes, ...ProfileModule.shellRoutes],
    ),
  ];
}

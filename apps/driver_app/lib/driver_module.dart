import 'dart:async';

import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/features/activity/activity_module.dart';
import 'package:driver_app/src/features/activity/data/repositories/driver_activity_repository.dart';
import 'package:driver_app/src/features/activity/domain/repositories/i_driver_activity_repository.dart';
import 'package:driver_app/src/features/chat/chat_module.dart';
import 'package:driver_app/src/features/home/home_module.dart';
import 'package:driver_app/src/features/home/data/repositories/dashboard_repository.dart';
import 'package:driver_app/src/features/home/data/data_sources/driver_remote_data_source.dart';
import 'package:driver_app/src/features/home/domain/repositories/i_dashboard_repository.dart';
import 'package:driver_app/src/features/home/presentation/bloc/dashboard_cubit.dart';
import 'package:driver_app/src/features/home/presentation/widgets/driver_tab.dart';
import 'package:driver_app/src/features/profile/profile_module.dart';
import 'package:driver_app/src/features/trip/data/repositories/ride_repository.dart';
import 'package:driver_app/src/features/trip/domain/repositories/i_ride_repository.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/trip/trip_module.dart';
import 'package:driver_app/src/features/trip/data/data_sources/bidding_remote_data_source.dart';
import 'package:driver_app/src/features/trip/data/data_sources/telemetry_remote_data_source.dart';
import 'package:driver_app/src/features/trip/data/data_sources/trip_remote_data_source.dart';

class DriverModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i
      ..addLazySingleton<IDashboardRepository>(
        (i) => DashboardRepository(
          remoteDataSource: i.get<TripRemoteDataSource>(),
          driverRemoteDataSource: i.get<DriverRemoteDataSource>(),
          sessionService: i.get<SecureSessionService>(),
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
      ..addFactory<DashboardCubit>(
        (i) => DashboardCubit(repository: i.get<IDashboardRepository>()),
      )
      ..addFactory<LiveMapBloc>(
        (i) => LiveMapBloc(
          telemetryDataSource: i.get<TelemetryRemoteDataSource>(),
          sessionService: i.get<SecureSessionService>(),
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

    ShellModularRoute(
      builder: (context, GoRouterState state, child) =>
          DriverShellLayout(child: child),
      routes: [...HomeModule.shellRoutes, ...ProfileModule.shellRoutes],
    ),
  ];
}

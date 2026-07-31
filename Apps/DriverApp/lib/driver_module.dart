import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:driver_app/src/Core/Network/DriverOperationsClient.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/Features/Activity/ActivityModule.dart';
import 'package:driver_app/src/Features/Activity/Data/Repositories/DriverActivityRepositoryImpl.dart';
import 'package:driver_app/src/Features/Activity/Domain/Repositories/DriverActivityRepository.dart';
import 'package:driver_app/src/Features/Chat/ChatModule.dart';
import 'package:driver_app/src/Features/Home/HomeModule.dart';
import 'package:driver_app/src/Features/Home/Data/Repositories/DashboardRepositoryImpl.dart';
import 'package:driver_app/src/Features/Home/Presentation/Bloc/DashboardCubit.dart';
import 'package:driver_app/src/Features/Home/Presentation/Widgets/DriverTab.dart';
import 'package:driver_app/src/Features/Profile/ProfileModule.dart';
import 'package:driver_app/src/Features/Trip/Data/Repositories/RideRepositoryImpl.dart';
import 'package:driver_app/src/Features/Trip/Presentation/Bloc/LiveMap/LiveMapBloc.dart';
import 'package:driver_app/src/Features/Trip/Presentation/Bloc/RideFlow/RideFlowCubit.dart';
import 'package:driver_app/src/Core/Services/SecureSessionService.dart';
import 'package:driver_app/src/Features/Trip/Data/DataSources/BiddingRemoteDataSource.dart';
import 'package:driver_app/src/Features/Trip/Data/DataSources/TelemetryRemoteDataSource.dart';
import 'package:driver_app/src/Features/Trip/Data/DataSources/TripRemoteDataSource.dart';
import 'package:driver_app/src/Features/Trip/Data/DataSources/PassengerRemoteDataSource.dart';

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
        (i) => RideRepositoryImpl(
          remoteDataSource: i.get<BiddingRemoteDataSource>(),
        ),
      )
      ..addLazySingleton<DriverActivityRepository>(
        (i) => DriverActivityRepositoryImpl(
          remoteDataSource: i.get<TripRemoteDataSource>(),
        ),
      )
      ..addFactory<DashboardCubit>(
        (i) => DashboardCubit(
          repository: i.get<DashboardRepository>(),
          operationsClient: i.get<DriverOperationsClient>(),
        ),
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

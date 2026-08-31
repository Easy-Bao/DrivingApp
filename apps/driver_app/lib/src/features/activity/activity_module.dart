import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/activity/activity_routes.dart';
import 'package:driver_app/src/features/activity/presentation/bloc/earnings/earnings_cubit.dart';
import 'package:driver_app/src/features/activity/presentation/bloc/performance/driver_performance_cubit.dart';
import 'package:driver_app/src/features/activity/presentation/bloc/trip_history/trip_history_cubit.dart';
import 'package:driver_app/src/features/activity/data/data_sources/driver_activity_remote_data_source.dart';
import 'package:driver_app/src/features/activity/data/repositories/driver_activity_repository.dart';
import 'package:driver_app/src/features/activity/domain/repositories/i_driver_activity_repository.dart';
import 'package:driver_app/src/features/activity/presentation/driver_trip_history_page.dart';
import 'package:driver_app/src/features/activity/presentation/driver_trip_detail_page.dart';
import 'package:driver_app/src/features/activity/presentation/driver_performance_page.dart';
import 'package:driver_app/src/features/activity/presentation/earnings_page.dart';
import 'package:design_system/design_system.dart';

class ActivityModule {
  ActivityModule._();

  static void binds(Injector i) {
    i
      ..addLazySingleton<DriverActivityRemoteDataSource>(
        (i) => DriverActivityRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<IDriverActivityRepository>(
        (i) => DriverActivityRepository(
          remoteDataSource: i.get<DriverActivityRemoteDataSource>(),
        ),
      )
      ..addFactory<DriverEarningsCubit>(
        (i) => DriverEarningsCubit(
          repository: i.get<IDriverActivityRepository>(),
          sessionService: i.get<SecureSessionService>(),
        ),
      )
      ..addFactory<DriverPerformanceCubit>(
        (i) => DriverPerformanceCubit(
          repository: i.get<IDriverActivityRepository>(),
          sessionService: i.get<SecureSessionService>(),
        ),
      )
      ..addFactory<DriverTripHistoryCubit>(
        (i) => DriverTripHistoryCubit(
          repository: i.get<IDriverActivityRepository>(),
          sessionService: i.get<SecureSessionService>(),
        ),
      );
  }

  static List<ModularRoute> routes = [
    ChildRoute(
      name: ActivityRoutes.tripDetail,
      ActivityRoutes.tripDetailPath,
      child: (context, GoRouterState state) =>
          DriverTripDetailPage(trip: SafeRouteExtra.asMap(state.extra)),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: ActivityRoutes.performance,
      ActivityRoutes.performancePath,
      child: (context, GoRouterState state) => BlocProvider(
        create: (_) {
          final cubit = Modular.get<DriverPerformanceCubit>();
          unawaited(cubit.load());
          return cubit;
        },
        child: const DriverPerformancePage(),
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];

  static List<ModularRoute> earningsShellRoutes = [
    ChildRoute(
      name: ActivityRoutes.earnings,
      ActivityRoutes.earningsPath,
      child: (context, GoRouterState state) => BlocProvider(
        create: (_) {
          final cubit = Modular.get<DriverEarningsCubit>();
          cubit.load();
          return cubit;
        },
        child: const DriverEarningsPage(),
      ),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: ActivityRoutes.tripHistory,
      ActivityRoutes.tripHistoryPath,
      child: (context, GoRouterState state) => BlocProvider(
        create: (_) {
          final cubit = Modular.get<DriverTripHistoryCubit>();
          cubit.load();
          return cubit;
        },
        child: const DriverTripHistoryPage(),
      ),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}

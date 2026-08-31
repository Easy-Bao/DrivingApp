import 'dart:async';

import 'package:dio/dio.dart';
import 'package:driver_app/src/features/performance/data/data_sources/driver_performance_remote_data_source.dart';
import 'package:driver_app/src/features/performance/data/repositories/driver_performance_repository_impl.dart';
import 'package:driver_app/src/features/performance/domain/repositories/driver_performance_repository.dart';
import 'package:driver_app/src/features/performance/performance_routes.dart';
import 'package:driver_app/src/features/performance/presentation/bloc/driver_performance_cubit.dart';
import 'package:driver_app/src/features/performance/presentation/view/driver_performance_page.dart';
import 'package:driver_app/src/infrastructure/session/driver_session_store.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';

class PerformanceModule {
  PerformanceModule._();

  static void binds(Injector i) {
    i
      ..addLazySingleton<DriverPerformanceRemoteDataSource>(
        (i) => DriverPerformanceRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<DriverPerformanceRepository>(
        (i) => DriverPerformanceRepositoryImpl(
          dataSource: i.get<DriverPerformanceRemoteDataSource>(),
        ),
      )
      ..addFactory<DriverPerformanceCubit>(
        (i) => DriverPerformanceCubit(
          repository: i.get<DriverPerformanceRepository>(),
          sessionService: i.get<DriverSessionStore>(),
        ),
      );
  }

  static final List<ModularRoute> routes = [
    ChildRoute(
      name: PerformanceRoutes.performance,
      PerformanceRoutes.performancePath,
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
}

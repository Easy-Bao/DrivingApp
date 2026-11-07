import 'dart:async';

import 'package:dio/dio.dart';
import 'package:driver/src/features/performance/data/datasources/performance_remote_data_source.dart';
import 'package:driver/src/features/performance/data/repositories/performance_repository_impl.dart';
import 'package:driver/src/features/performance/domain/repositories/performance_repository.dart';
import 'package:driver/src/features/performance/performance_routes.dart';
import 'package:driver/src/features/performance/presentation/bloc/performance_cubit.dart';
import 'package:driver/src/features/performance/presentation/pages/performance_page.dart';
import 'package:driver/src/core/session/session_store.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';

class PerformanceModule._() {
  static void binds(Injector i) {
    i
      ..addLazySingleton<PerformanceRemoteDataSource>(
        (i) => PerformanceRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<PerformanceRepository>(
        (i) => PerformanceRepositoryImpl(
          dataSource: i.get<PerformanceRemoteDataSource>(),
        ),
      )
      ..addFactory<PerformanceCubit>(
        (i) => PerformanceCubit(
          repository: i.get<PerformanceRepository>(),
          sessionService: i.get<SessionStore>(),
        ),
      );
  }

  static final List<ModularRoute> routes = [
    ChildRoute(
      name: PerformanceRoutes.performance,
      PerformanceRoutes.performancePath,
      child: (context, GoRouterState state) => BlocProvider(
        create: (_) {
          final cubit = Modular.get<PerformanceCubit>();
          unawaited(cubit.load());
          return cubit;
        },
        child: const PerformancePage(),
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];
}

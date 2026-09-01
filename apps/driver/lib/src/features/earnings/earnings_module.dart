import 'package:dio/dio.dart';
import 'package:driver/src/features/earnings/data/data_sources/driver_earnings_remote_data_source.dart';
import 'package:driver/src/features/earnings/data/repositories/driver_earnings_repository_impl.dart';
import 'package:driver/src/features/earnings/domain/repositories/driver_earnings_repository.dart';
import 'package:driver/src/features/earnings/earnings_routes.dart';
import 'package:driver/src/features/earnings/presentation/bloc/earnings_cubit.dart';
import 'package:driver/src/features/earnings/presentation/view/earnings_page.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';

class EarningsModule._() {
  static void binds(Injector i) {
    i
      ..addLazySingleton<DriverEarningsRemoteDataSource>(
        (i) => DriverEarningsRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<DriverEarningsRepository>(
        (i) => DriverEarningsRepositoryImpl(
          dataSource: i.get<DriverEarningsRemoteDataSource>(),
        ),
      )
      ..addFactory<DriverEarningsCubit>(
        (i) => DriverEarningsCubit(
          repository: i.get<DriverEarningsRepository>(),
          sessionService: i.get<DriverSessionStore>(),
        ),
      );
  }

  static final List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: EarningsRoutes.earnings,
      EarningsRoutes.earningsPath,
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
}

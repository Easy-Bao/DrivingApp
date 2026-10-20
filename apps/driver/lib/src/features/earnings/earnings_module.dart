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
      ..addLazySingleton<EarningsRemoteDataSource>(
        (i) => EarningsRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<EarningsRepository>(
        (i) => EarningsRepositoryImpl(
          dataSource: i.get<EarningsRemoteDataSource>(),
        ),
      )
      ..addFactory<EarningsCubit>(
        (i) => EarningsCubit(
          repository: i.get<EarningsRepository>(),
          sessionService: i.get<SessionStore>(),
        ),
      );
  }

  static final List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: EarningsRoutes.earnings,
      EarningsRoutes.earningsPath,
      child: (context, GoRouterState state) => BlocProvider(
        create: (_) {
          final cubit = Modular.get<EarningsCubit>();
          cubit.load();
          return cubit;
        },
        child: const EarningsPage(),
      ),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}

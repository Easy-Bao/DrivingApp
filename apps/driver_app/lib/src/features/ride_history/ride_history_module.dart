import 'package:dio/dio.dart';
import 'package:driver_app/src/features/ride_history/data/data_sources/driver_ride_history_remote_data_source.dart';
import 'package:driver_app/src/features/ride_history/data/repositories/driver_ride_history_repository_impl.dart';
import 'package:driver_app/src/features/ride_history/domain/repositories/driver_ride_history_repository.dart';
import 'package:driver_app/src/features/ride_history/presentation/bloc/trip_history_cubit.dart';
import 'package:driver_app/src/features/ride_history/presentation/view/driver_trip_detail_page.dart';
import 'package:driver_app/src/features/ride_history/presentation/view/driver_trip_history_page.dart';
import 'package:driver_app/src/features/ride_history/ride_history_routes.dart';
import 'package:driver_app/src/infrastructure/session/driver_session_store.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';

class RideHistoryModule {
  RideHistoryModule._();

  static void binds(Injector i) {
    i
      ..addLazySingleton<DriverRideHistoryRemoteDataSource>(
        (i) => DriverRideHistoryRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<DriverRideHistoryRepository>(
        (i) => DriverRideHistoryRepositoryImpl(
          dataSource: i.get<DriverRideHistoryRemoteDataSource>(),
        ),
      )
      ..addFactory<DriverTripHistoryCubit>(
        (i) => DriverTripHistoryCubit(
          repository: i.get<DriverRideHistoryRepository>(),
          sessionService: i.get<DriverSessionStore>(),
        ),
      );
  }

  static final List<ModularRoute> routes = [
    ChildRoute(
      name: RideHistoryRoutes.tripDetail,
      RideHistoryRoutes.tripDetailPath,
      child: (context, GoRouterState state) =>
          DriverTripDetailPage(trip: SafeRouteExtra.asMap(state.extra)),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];

  static final List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: RideHistoryRoutes.tripHistory,
      RideHistoryRoutes.tripHistoryPath,
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

import 'package:dio/dio.dart';
import 'package:driver_app/src/infrastructure/telemetry/driver_background_telemetry.dart';
import 'package:driver_app/src/infrastructure/session/driver_session_store.dart';
import 'package:driver_app/src/features/dashboard/data/data_sources/driver_availability_remote_data_source.dart';
import 'package:driver_app/src/features/dashboard/data/data_sources/ride_offer_remote_data_source.dart';
import 'package:driver_app/src/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:driver_app/src/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:driver_app/src/features/active_ride/domain/repositories/driver_ride_repository.dart';
import 'package:driver_app/src/features/performance/domain/repositories/driver_performance_repository.dart';
import 'package:driver_app/src/features/ride_history/domain/repositories/driver_ride_history_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/features/dashboard/dashboard_routes.dart';
import 'package:driver_app/src/features/dashboard/presentation/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver_app/src/features/dashboard/presentation/view/driver_dashboard_page.dart';
import 'package:foundation/foundation.dart';
import 'package:design_system/design_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardModule {
  DashboardModule._();

  static void binds(Injector i) {
    i
      ..addLazySingleton<DriverAvailabilityRemoteDataSource>(
        (i) => DriverAvailabilityRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<RideOfferRemoteDataSource>(
        (i) => RideOfferRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<DashboardRepository>(
        (i) => DashboardRepositoryImpl(
          performanceRepository: i.get<DriverPerformanceRepository>(),
          rideHistoryRepository: i.get<DriverRideHistoryRepository>(),
          availabilityDataSource: i.get<DriverAvailabilityRemoteDataSource>(),
          rideOfferDataSource: i.get<RideOfferRemoteDataSource>(),
          rideRepository: i.get<DriverRideRepository>(),
          sessionService: i.get<DriverSessionStore>(),
          preferences: i.get<SharedPreferences>(),
          backgroundTelemetryService: i.get<DriverBackgroundTelemetry>(),
        ),
      )
      ..addLazySingleton<DashboardCubit>(
        (i) => DashboardCubit(repository: i.get<DashboardRepository>()),
      );
  }

  static List<ModularRoute> routes = [];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: DashboardRoutes.dashboard,
      DashboardRoutes.dashboardPath,
      child: (context, GoRouterState state) => BlocProvider.value(
        value: Modular.get<DashboardCubit>()..initialize(),
        child: DriverDashboardPage(
          lifecycleCoordinator: Modular.get<AppLifecycleCoordinator>(),
        ),
      ),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}

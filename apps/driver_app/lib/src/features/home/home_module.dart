import 'package:dio/dio.dart';
import 'package:driver_app/src/core/services/background_telemetry_service.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/activity/data/datasources/driver_activity_remote_data_source.dart';
import 'package:driver_app/src/features/home/data/datasources/driver_availability_remote_data_source.dart';
import 'package:driver_app/src/features/home/data/datasources/ride_offer_remote_data_source.dart';
import 'package:driver_app/src/features/home/data/repositories/dashboard_repository.dart';
import 'package:driver_app/src/features/home/domain/repositories/i_dashboard_repository.dart';
import 'package:driver_app/src/features/trip/data/datasources/telemetry_remote_data_source.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/features/home/home_routes.dart';
import 'package:driver_app/src/features/home/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver_app/src/features/home/view/driver_dashboard_page.dart';
import 'package:shared_ui/shared_ui.dart';

class HomeModule {
  HomeModule._();

  static void binds(Injector i) {
    i
      ..addLazySingleton<DriverAvailabilityRemoteDataSource>(
        (i) => DriverAvailabilityRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<RideOfferRemoteDataSource>(
        (i) => RideOfferRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<IDashboardRepository>(
        (i) => DashboardRepository(
          activityDataSource: i.get<DriverActivityRemoteDataSource>(),
          availabilityDataSource: i.get<DriverAvailabilityRemoteDataSource>(),
          telemetryRemoteDataSource: i.get<TelemetryRemoteDataSource>(),
          sessionService: i.get<SecureSessionService>(),
          backgroundTelemetryService: i.get<BackgroundTelemetryService>(),
        ),
      )
      ..addLazySingleton<DashboardCubit>(
        (i) => DashboardCubit(repository: i.get<IDashboardRepository>()),
      );
  }

  static List<ModularRoute> routes = [];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: HomeRoutes.dashboard,
      HomeRoutes.dashboardPath,
      child: (context, GoRouterState state) => BlocProvider.value(
        value: Modular.get<DashboardCubit>()..initialize(),
        child: const DriverDashboardPage(),
      ),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}

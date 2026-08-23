import 'package:dio/dio.dart';
import 'package:driver_app/src/core/services/background_telemetry_service.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/features/activity/domain/repositories/i_driver_activity_repository.dart';
import 'package:driver_app/src/features/home/data/datasources/driver_availability_remote_data_source.dart';
import 'package:driver_app/src/features/home/data/datasources/ride_offer_remote_data_source.dart';
import 'package:driver_app/src/features/home/data/repositories/dashboard_repository.dart';
import 'package:driver_app/src/features/home/domain/repositories/i_dashboard_repository.dart';
import 'package:driver_app/src/features/trip/domain/repositories/i_driver_ride_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/features/home/home_routes.dart';
import 'package:driver_app/src/features/home/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver_app/src/features/home/view/driver_dashboard_page.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          activityRepository: i.get<IDriverActivityRepository>(),
          availabilityDataSource: i.get<DriverAvailabilityRemoteDataSource>(),
          rideOfferDataSource: i.get<RideOfferRemoteDataSource>(),
          rideRepository: i.get<IDriverRideRepository>(),
          sessionService: i.get<SecureSessionService>(),
          preferences: i.get<SharedPreferences>(),
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
        child: DriverDashboardPage(
          repository: Modular.get<IDashboardRepository>(),
        ),
      ),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}

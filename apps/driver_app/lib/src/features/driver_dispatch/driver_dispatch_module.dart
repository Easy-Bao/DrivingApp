import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:driver_app/src/core/transitions/app_transitions.dart';
import 'package:driver_app/src/features/dashboard/dashboard_module.dart';
import 'package:driver_app/src/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:driver_app/src/features/dashboard/data/repositories/driver_activity_repository_impl.dart';
import 'package:driver_app/src/features/dashboard/domain/repositories/driver_activity_repository.dart';
import 'package:driver_app/src/features/dashboard/presentation/blocs/dashboard/dashboard_cubit.dart';
import 'package:driver_app/src/features/dashboard/presentation/views/layout/driver_tab.dart';
import 'package:driver_app/src/features/driver_dispatch/data/repositories/ride_repository_impl.dart';
import 'package:driver_app/src/features/driver_dispatch/driver_routes.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/live_map/live_map_bloc.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/ride/ride_flow_cubit.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/views/payment/fare_summary_screen.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/views/payment/rate_passenger_screen.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/views/ride/complete_trip_screen.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/views/ride/en_route_pickup_screen.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/views/ride/in_transit_screen.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/views/ride/waiting_passenger_screen.dart';
import 'package:driver_services/driver_services.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:session_service/session_service.dart';

class DriverDispatchModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i
      ..addLazySingleton<DashboardRepository>(
        (i) => DashboardRepositoryImpl(apiService: i.get<TripApiService>()),
      )
      ..addLazySingleton<RideRepository>(
        (i) => RideRepositoryImpl(apiService: i.get<BiddingApiService>()),
      )
      ..addLazySingleton<DriverActivityRepository>(
        (i) => DriverActivityRepositoryImpl(
          apiService: i.get<TripApiService>(),
        ),
      )
      ..addFactory<DashboardCubit>(
        (i) => DashboardCubit(repository: i.get<DashboardRepository>()),
      )
      ..addFactory<LiveMapBloc>(
        (i) => LiveMapBloc(
          telemetryService: i.get<TelemetryApiService>(),
          sessionService: i.get<SecureSessionService>(),
        ),
      )
      ..addFactory<RideFlowCubit>(
        (i) => RideFlowCubit(
          repository: i.get<RideRepository>(),
          apiService: i.get<TripApiService>(),
        ),
      );
  }
  @override
  List<ModularRoute> get routes => <ModularRoute>[
        // Composite Dashboard & Chat routes
        ...DashboardModule.routes,

        // Live ride-hailing / bidding flows
        ChildRoute(
          name: DriverRoutes.enRoutePickup,
          'ride/en-route',
          child: (context, GoRouterState state) {
            final d = state.extra as Map<String, dynamic>;
            return EnRoutePickupScreen(
              pickup: d['pickup'] as String,
              dropoff: d['dropoff'] as String,
              distance: (d['distance'] as num).toDouble(),
              fare: (d['fare'] as num).toDouble(),
              duration: d['duration'] as String,
            );
          },
          transition: AppTransitions.push.toLeft,
          transitionDuration: AppTransitions.pushDuration,
        ),
        ChildRoute(
          name: DriverRoutes.waitingPassenger,
          'ride/waiting',
          child: (context, GoRouterState state) {
            final d = state.extra as Map<String, dynamic>;
            return WaitingPassengerScreen(
              pickup: d['pickup'] as String,
              dropoff: d['dropoff'] as String,
              distance: (d['distance'] as num).toDouble(),
              fare: (d['fare'] as num).toDouble(),
              duration: d['duration'] as String,
            );
          },
          transition: AppTransitions.push.toLeft,
          transitionDuration: AppTransitions.pushDuration,
        ),
        ChildRoute(
          name: DriverRoutes.inTransit,
          'ride/in-transit',
          child: (context, GoRouterState state) {
            final d = state.extra as Map<String, dynamic>;
            return InTransitScreen(
              pickup: d['pickup'] as String,
              dropoff: d['dropoff'] as String,
              distance: (d['distance'] as num).toDouble(),
              fare: (d['fare'] as num).toDouble(),
              duration: d['duration'] as String,
            );
          },
          transition: AppTransitions.push.toLeft,
          transitionDuration: AppTransitions.pushDuration,
        ),
        ChildRoute(
          name: DriverRoutes.completeTripDriver,
          'ride/complete',
          child: (context, GoRouterState state) {
            final d = state.extra as Map<String, dynamic>;
            return CompleteTripScreen(
              pickup: d['pickup'] as String,
              dropoff: d['dropoff'] as String,
              distance: (d['distance'] as num).toDouble(),
              fare: (d['fare'] as num).toDouble(),
              duration: d['duration'] as String,
            );
          },
          transition: AppTransitions.modal.toTop,
          transitionDuration: AppTransitions.modalDuration,
        ),
        ChildRoute(
          name: DriverRoutes.fareSummary,
          'ride/fare-summary',
          child: (context, GoRouterState state) {
            final d = state.extra as Map<String, dynamic>;
            return FareSummaryScreen(
              pickup: d['pickup'] as String,
              dropoff: d['dropoff'] as String,
              distance: (d['distance'] as num).toDouble(),
              fare: (d['fare'] as num).toDouble(),
              duration: d['duration'] as String,
            );
          },
          transition: AppTransitions.modal.toTop,
          transitionDuration: AppTransitions.modalDuration,
        ),
        ChildRoute(
          name: DriverRoutes.ratePassenger,
          'ride/rate',
          child: (context, GoRouterState state) => const RatePassengerScreen(),
          transition: AppTransitions.modal.toTop,
          transitionDuration: AppTransitions.modalDuration,
        ),

        // Shell route for bottom tab navigation
        ShellModularRoute(
          builder: (context, GoRouterState state, child) =>
              DriverShellLayout(child: child),
          routes: [
            ...DashboardModule.shellRoutes,
          ],
        ),
      ];
}

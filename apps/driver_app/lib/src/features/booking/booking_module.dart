import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:shared_ui/transitions/driver_transitions.dart';
import 'package:driver_app/src/features/home/home_module.dart';
import 'package:driver_app/src/features/home/data/repositories/dashboard_repository_impl.dart';
import 'package:driver_app/src/features/activity/data/repositories/driver_activity_repository_impl.dart';
import 'package:driver_app/src/features/activity/domain/repositories/driver_activity_repository.dart';
import 'package:driver_app/src/features/home/presentation/bloc/dashboard_cubit.dart';
import 'package:driver_app/src/features/home/presentation/widgets/driver_tab.dart';
import 'package:driver_app/src/features/booking/data/repositories/ride_repository_impl.dart';
import 'package:driver_app/src/features/booking/driver_routes.dart';
import 'package:driver_app/src/features/booking/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:driver_app/src/features/booking/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver_app/src/features/booking/presentation/screens/fare_summary_screen.dart';
import 'package:driver_app/src/features/booking/presentation/screens/rate_passenger_screen.dart';
import 'package:driver_app/src/features/booking/presentation/screens/complete_trip_screen.dart';
import 'package:driver_app/src/features/booking/presentation/screens/en_route_pickup_screen.dart';
import 'package:driver_app/src/features/booking/presentation/screens/in_transit_screen.dart';
import 'package:driver_app/src/features/booking/presentation/screens/waiting_passenger_screen.dart';
import 'package:driver_services/driver_services.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:session_service/session_service.dart';

class DriverDispatchModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i
      ..addLazySingleton<DashboardRepository>(
        (i) => DashboardRepositoryImpl(
          apiService: i.get<TripApiService>(),
          sessionService: i.get<SecureSessionService>(),
        ),
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
          sessionService: i.get<DriverSessionService>(),
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

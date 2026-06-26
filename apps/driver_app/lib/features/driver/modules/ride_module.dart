import 'package:driver_app/features/driver/presentation/views/payment/fare_summary_screen.dart';
import 'package:driver_app/features/driver/presentation/views/payment/rate_passenger_screen.dart';
import 'package:driver_app/features/driver/presentation/views/ride/complete_trip_screen.dart';
import 'package:driver_app/features/driver/presentation/views/ride/en_route_pickup_screen.dart';
import 'package:driver_app/features/driver/presentation/views/ride/in_transit_screen.dart';
import 'package:driver_app/features/driver/presentation/views/ride/route_optimizer_screen.dart';
import 'package:driver_app/features/driver/presentation/views/ride/waiting_passenger_screen.dart';
import 'package:driver_app/core/transitions/app_transitions.dart';
import 'package:go_router_modular/go_router_modular.dart';

class RideModule {
  RideModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: 'EnRoutePickup',
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
      name: 'WaitingPassenger',
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
      name: 'InTransit',
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
      name: 'CompleteTripDriver',
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
      name: 'FareSummary',
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
      name: 'RatePassenger',
      'ride/rate',
      child: (context, GoRouterState state) => const RatePassengerScreen(),
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
    ChildRoute(
      name: 'RouteOptimizer',
      'ride/optimize',
      child: (context, GoRouterState state) => const RouteOptimizerScreen(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];
}

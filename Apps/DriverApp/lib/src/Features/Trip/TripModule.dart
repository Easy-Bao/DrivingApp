import 'package:go_router_modular/go_router_modular.dart';

import 'package:driver_app/src/Features/Trip/TripRoutes.dart';
import 'package:driver_app/src/Features/Trip/Presentation/Screens/CompleteTripScreen.dart';
import 'package:driver_app/src/Features/Trip/Presentation/Screens/EnRoutePickupScreen.dart';
import 'package:driver_app/src/Features/Trip/Presentation/Screens/FareSummaryScreen.dart';
import 'package:driver_app/src/Features/Trip/Presentation/Screens/InTransitScreen.dart';
import 'package:driver_app/src/Features/Trip/Presentation/Screens/RatePassengerScreen.dart';
import 'package:driver_app/src/Features/Trip/Presentation/Screens/RideAlertScreen.dart';
import 'package:driver_app/src/Features/Trip/Presentation/Screens/WaitingPassengerScreen.dart';
import 'package:shared_ui/shared_ui.dart';

class TripModule {
  TripModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: TripRoutes.rideAlert,
      'dashboard/ride-alert',
      child: (context, GoRouterState state) =>
          RideAlertScreen(rideData: SafeRouteExtra.asMap(state.extra)),
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
    ChildRoute(
      name: TripRoutes.enRoutePickup,
      'ride/en-route',
      child: (context, GoRouterState state) {
        final data = SafeRouteExtra.asMap(state.extra);
        return EnRoutePickupScreen(
          pickup: data['pickup'] as String,
          dropoff: data['dropoff'] as String,
          distance: (data['distance'] as num).toDouble(),
          fare: (data['fare'] as num).toDouble(),
          duration: data['duration'] as String,
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: TripRoutes.waitingPassenger,
      'ride/waiting',
      child: (context, GoRouterState state) {
        final data = SafeRouteExtra.asMap(state.extra);
        return WaitingPassengerScreen(
          pickup: data['pickup'] as String,
          dropoff: data['dropoff'] as String,
          distance: (data['distance'] as num).toDouble(),
          fare: (data['fare'] as num).toDouble(),
          duration: data['duration'] as String,
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: TripRoutes.inTransit,
      'ride/in-transit',
      child: (context, GoRouterState state) {
        final data = SafeRouteExtra.asMap(state.extra);
        return InTransitScreen(
          pickup: data['pickup'] as String,
          dropoff: data['dropoff'] as String,
          distance: (data['distance'] as num).toDouble(),
          fare: (data['fare'] as num).toDouble(),
          duration: data['duration'] as String,
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: TripRoutes.completeTrip,
      'ride/complete',
      child: (context, GoRouterState state) {
        final data = SafeRouteExtra.asMap(state.extra);
        return CompleteTripScreen(
          pickup: data['pickup'] as String,
          dropoff: data['dropoff'] as String,
          distance: (data['distance'] as num).toDouble(),
          fare: (data['fare'] as num).toDouble(),
          duration: data['duration'] as String,
        );
      },
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
    ChildRoute(
      name: TripRoutes.fareSummary,
      'ride/fare-summary',
      child: (context, GoRouterState state) {
        final data = SafeRouteExtra.asMap(state.extra);
        return FareSummaryScreen(
          pickup: data['pickup'] as String,
          dropoff: data['dropoff'] as String,
          distance: (data['distance'] as num).toDouble(),
          fare: (data['fare'] as num).toDouble(),
          duration: data['duration'] as String,
        );
      },
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
    ChildRoute(
      name: TripRoutes.ratePassenger,
      'ride/rate',
      child: (context, GoRouterState state) => const RatePassengerScreen(),
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [];
}

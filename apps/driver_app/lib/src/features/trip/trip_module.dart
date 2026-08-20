import 'package:go_router_modular/go_router_modular.dart';

import 'package:driver_app/src/features/trip/trip_routes.dart';
import 'package:driver_app/src/features/trip/view/pickup_navigation_page.dart';
import 'package:driver_app/src/features/trip/view/fare_summary_page.dart';
import 'package:driver_app/src/features/trip/view/in_transit_page.dart';
import 'package:driver_app/src/features/trip/view/waiting_passenger_page.dart';
import 'package:shared_ui/shared_ui.dart';

class TripModule {
  TripModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: TripRoutes.pickupNavigation,
      TripRoutes.pickupNavigationPath,
      child: (context, GoRouterState state) {
        final data = SafeRouteExtra.asMap(state.extra);
        return PickupNavigationPage(
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
      TripRoutes.waitingPassengerPath,
      child: (context, GoRouterState state) {
        final data = SafeRouteExtra.asMap(state.extra);
        return WaitingPassengerPage(
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
      TripRoutes.inTransitPath,
      child: (context, GoRouterState state) {
        final data = SafeRouteExtra.asMap(state.extra);
        return InTransitPage(
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
      name: TripRoutes.fareSummary,
      TripRoutes.fareSummaryPath,
      child: (context, GoRouterState state) {
        final data = SafeRouteExtra.asMap(state.extra);
        return FareSummaryPage(
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
  ];

  static List<ModularRoute> shellRoutes = [];
}

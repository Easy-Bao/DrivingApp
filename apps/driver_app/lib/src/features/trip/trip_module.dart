import 'package:go_router_modular/go_router_modular.dart';

import 'package:driver_app/src/features/trip/trip_routes.dart';
import 'package:driver_app/src/features/trip/view/complete_trip_page.dart';
import 'package:driver_app/src/features/trip/view/en_route_pickup_page.dart';
import 'package:driver_app/src/features/trip/view/fare_summary_page.dart';
import 'package:driver_app/src/features/trip/view/in_transit_page.dart';
import 'package:driver_app/src/features/trip/view/rate_passenger_page.dart';
import 'package:driver_app/src/features/trip/view/ride_alert_page.dart';
import 'package:driver_app/src/features/trip/view/waiting_passenger_page.dart';
import 'package:shared_ui/shared_ui.dart';

class TripModule {
  TripModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: TripRoutes.rideAlert,
      'dashboard/ride-alert',
      child: (context, GoRouterState state) =>
          RideAlertPage(rideData: SafeRouteExtra.asMap(state.extra)),
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
    ChildRoute(
      name: TripRoutes.enRoutePickup,
      'ride/en-route',
      child: (context, GoRouterState state) {
        final data = SafeRouteExtra.asMap(state.extra);
        return EnRoutePickupPage(
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
      'ride/in-transit',
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
      name: TripRoutes.completeTrip,
      'ride/complete',
      child: (context, GoRouterState state) {
        final data = SafeRouteExtra.asMap(state.extra);
        return CompleteTripPage(
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
    ChildRoute(
      name: TripRoutes.ratePassenger,
      'ride/rate',
      child: (context, GoRouterState state) {
        final data = SafeRouteExtra.asMap(state.extra);
        return RatePassengerPage(
          rideId: data['rideId']?.toString() ?? '',
          passengerId: data['passengerId']?.toString() ?? '',
          passengerName: data['passengerName']?.toString() ?? 'Passenger',
        );
      },
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [];
}

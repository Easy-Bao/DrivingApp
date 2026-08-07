import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/activity/activity_routes.dart';
import 'package:passenger_app/src/features/activity/view/passenger_activity_page.dart';
import 'package:passenger_app/src/features/activity/view/passenger_payment_page.dart';
import 'package:passenger_app/src/features/activity/view/passenger_rating_page.dart';
import 'package:passenger_app/src/features/activity/view/view_all_activity_page.dart';
import 'package:passenger_app/src/features/activity/view/view_details_page.dart';
import 'package:passenger_app/src/features/trip/view/track_driver_page.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

class ActivityModule {
  ActivityModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: ActivityRoutes.viewAllRecentActivity,
      ActivityRoutes.viewAllRecentActivityPath,
      child: (context, GoRouterState state) =>
          const PassengerViewAllActivityPage(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: ActivityRoutes.activityViewDetails,
      ActivityRoutes.activityViewDetailsPath,
      child: (context, GoRouterState state) {
        final ride = state.extra is RideHistoryModel
            ? state.extra as RideHistoryModel
            : null;
        return ActivityViewDetailsPage(ride: ride);
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: ActivityRoutes.activityTrackDriver,
      ActivityRoutes.activityTrackDriverPath,
      child: (context, GoRouterState state) {
        final ride = state.extra is RideHistoryModel
            ? state.extra as RideHistoryModel
            : null;
        if (ride == null) {
          return const Scaffold(
            body: Center(child: Text('Trip tracking data not available.')),
          );
        }
        return ActivityTrackDriverPage(ride: ride);
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: ActivityRoutes.passengerRating,
      ActivityRoutes.passengerRatingPath,
      child: (context, GoRouterState state) {
        final driverId = state.uri.queryParameters['driverId'] ?? '';
        final driverName = state.uri.queryParameters['driverName'] ?? '';
        final rideId = state.uri.queryParameters['rideId'] ?? '';
        return PassengerRatingPage(
          driverId: driverId,
          driverName: driverName,
          rideId: rideId,
        );
      },
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
    ChildRoute(
      name: ActivityRoutes.passengerPayment,
      ActivityRoutes.passengerPaymentPath,
      child: (context, GoRouterState state) {
        final ride = state.extra is RideHistoryModel
            ? state.extra as RideHistoryModel
            : null;
        return ride == null
            ? const Scaffold(
                body: Center(child: Text('Payment data unavailable.')),
              )
            : PassengerPaymentPage(ride: ride);
      },
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: ActivityRoutes.activity,
      ActivityRoutes.activityPath,
      child: (context, GoRouterState state) => const PassengerActivityPage(),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}

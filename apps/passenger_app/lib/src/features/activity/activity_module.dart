import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/activity/activity_routes.dart';
import 'package:passenger_app/src/features/activity/presentation/screens/passenger_activity_screen.dart';
import 'package:passenger_app/src/features/activity/presentation/screens/passenger_rating_screen.dart';
import 'package:passenger_app/src/features/activity/presentation/screens/ride_history_screen.dart';
import 'package:passenger_app/src/features/activity/presentation/screens/view_all_activity_screen.dart';
import 'package:passenger_app/src/features/activity/presentation/screens/view_details_screen.dart';
import 'package:passenger_app/src/features/trip/presentation/screens/track_driver_screen.dart';
import 'package:shared_ui/transitions/passenger_transitions.dart';

class ActivityModule {
  ActivityModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: ActivityRoutes.viewAllRecentActivity,
      'activity/recent-activity',
      child: (context, GoRouterState state) =>
          const PassengerViewAllActivityScreen(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: ActivityRoutes.activityViewDetails,
      'activity/viewDetails',
      child: (context, GoRouterState state) {
        final ride = state.extra is RideHistoryModel
            ? state.extra as RideHistoryModel
            : null;
        return ActivityViewDetailsScreen(ride: ride);
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: ActivityRoutes.activityTrackDriver,
      'activity/trackDriver',
      child: (context, GoRouterState state) {
        final ride = state.extra is RideHistoryModel
            ? state.extra as RideHistoryModel
            : null;
        if (ride == null) {
          return const Scaffold(
            body: Center(child: Text('Trip tracking data not available.')),
          );
        }
        return ActivityTrackDriverScreen(ride: ride);
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: ActivityRoutes.rating,
      'activity/rating',
      child: (context, GoRouterState state) {
        final driverId = state.uri.queryParameters['driverId'] ?? '';
        final driverName = state.uri.queryParameters['driverName'] ?? '';
        return PassengerRatingScreen(
          driverId: driverId,
          driverName: driverName,
        );
      },
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
    ChildRoute(
      name: ActivityRoutes.rideHistory,
      'account/ride-history',
      child: (context, GoRouterState state) => const RideHistoryScreen(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: ActivityRoutes.activity,
      'activity',
      child: (context, GoRouterState state) => const PassengerActivityScreen(),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}

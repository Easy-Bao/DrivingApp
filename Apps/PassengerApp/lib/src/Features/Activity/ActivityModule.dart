import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/Features/Activity/ActivityRoutes.dart';
import 'package:passenger_app/src/Features/Activity/Presentation/Screens/PassengerActivityScreen.dart';
import 'package:passenger_app/src/Features/Activity/Presentation/Screens/PassengerRatingScreen.dart';
import 'package:passenger_app/src/Features/Activity/Presentation/Screens/ViewAllActivityScreen.dart';
import 'package:passenger_app/src/Features/Activity/Presentation/Screens/ViewDetailsScreen.dart';
import 'package:passenger_app/src/Features/Trip/Presentation/Screens/TrackDriverScreen.dart';
import 'package:shared_ui/shared_ui.dart';

class ActivityModule {
  ActivityModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: ActivityRoutes.viewAllRecentActivity,
      'activity/view-all',
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
      name: ActivityRoutes.passengerRating,
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

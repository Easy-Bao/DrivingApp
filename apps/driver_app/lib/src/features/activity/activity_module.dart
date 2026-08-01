import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/features/activity/activity_routes.dart';
import 'package:driver_app/src/features/activity/presentation/screens/driver_trip_history_screen.dart';
import 'package:driver_app/src/features/activity/presentation/screens/driver_trip_detail_screen.dart';
import 'package:shared_ui/shared_ui.dart';

class ActivityModule {
  ActivityModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: ActivityRoutes.tripHistory,
      'earnings/trip-history',
      child: (context, GoRouterState state) => const DriverTripHistoryScreen(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: ActivityRoutes.tripDetail,
      'earnings/trip-detail',
      child: (context, GoRouterState state) =>
          DriverTripDetailScreen(trip: SafeRouteExtra.asMap(state.extra)),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [];
}

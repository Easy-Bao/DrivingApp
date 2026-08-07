import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/features/activity/activity_routes.dart';
import 'package:driver_app/src/features/activity/view/driver_trip_history_page.dart';
import 'package:driver_app/src/features/activity/view/driver_trip_detail_page.dart';
import 'package:shared_ui/shared_ui.dart';

class ActivityModule {
  ActivityModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: ActivityRoutes.tripDetail,
      ActivityRoutes.tripDetailPath,
      child: (context, GoRouterState state) =>
          DriverTripDetailPage(trip: SafeRouteExtra.asMap(state.extra)),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: ActivityRoutes.tripHistory,
      ActivityRoutes.tripHistoryPath,
      child: (context, GoRouterState state) => const DriverTripHistoryPage(),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}

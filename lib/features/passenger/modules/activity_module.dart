import 'package:BaoRide/features/passenger/presentation/views/activity/track_driver.dart';
import 'package:BaoRide/features/passenger/presentation/views/activity/view_details.dart';
import 'package:BaoRide/features/passenger/presentation/views/passenger_activity.dart';
import 'package:go_router_modular/go_router_modular.dart';

class ActivityModule {
  static List<ModularRoute> routes = [
    ChildRoute(
      name: "ActivityViewDetails",
      "activity/viewDetails",
      child: (context, GoRouterState state) => ActivityViewDetails(),
      transition: GoTransitions.fadeUpwards,
      transitionDuration: Duration(milliseconds: 300),
    ),
    ChildRoute(
      name: "ActivityTrackDriver",
      "activity/trackDriver",
      child: (context, GoRouterState state) => AcitivityTrackDriver(),
      transition: GoTransitions.fadeUpwards,
      transitionDuration: Duration(milliseconds: 300),
    ),
  ];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: "PassengerActivity",
      "activity",
      child: (context, GoRouterState state) => PassengerActivityScreen(),
    ),
  ];
}

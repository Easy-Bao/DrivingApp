import 'package:BaoRide/features/passenger/presentation/views/passenger_activity.dart';
import 'package:go_router_modular/go_router_modular.dart';

class ActivityModule {
  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      "activity",
      child: (context, GoRouterState state) => PassengerActivityScreen(),
    ),
  ];
}

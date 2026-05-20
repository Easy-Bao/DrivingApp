import 'package:BaoRide/features/driver/presentation/views/dashboard/ride_alert_screen.dart';
import 'package:BaoRide/features/driver/presentation/views/driver_dashboard.dart';
import 'package:go_router_modular/go_router_modular.dart';

class DashboardModule {
  static List<ModularRoute> routes = [
    ChildRoute(
      name: "RideAlert",
      "dashboard/ride-alert",
      child: (context, GoRouterState state) => const RideAlertScreen(),
      transition: GoTransitions.fadeUpwards,
      transitionDuration: Duration(milliseconds: 300),
    ),
  ];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: "DriverDashboard",
      "dashboard",
      child: (context, GoRouterState state) => const DriverDashboardScreen(),
    ),
  ];
}

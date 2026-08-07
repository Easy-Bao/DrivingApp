import 'package:driver_app/src/core/routing/app_routes.dart';

abstract final class HomeRoutes {
  static const String dashboard = 'Dashboard';
  static const String dashboardPath = 'dashboard';
  static const String fullDashboardPath =
      '${AppRoutes.driverModulePath}$dashboardPath';
}

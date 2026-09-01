import 'package:driver/src/app/navigation/app_routes.dart';

abstract final class DashboardRoutes {
  static const String dashboard = 'Dashboard';
  static const String dashboardPath = 'dashboard';
  static const String fullDashboardPath =
      '${AppRoutes.driverModulePath}$dashboardPath';
}

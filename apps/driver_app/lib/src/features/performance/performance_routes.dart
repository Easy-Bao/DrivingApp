import 'package:driver_app/src/app/navigation/app_routes.dart';

abstract final class PerformanceRoutes {
  static const String performance = 'DriverPerformance';
  static const String performancePath = 'account/performance';
  static const String fullPerformancePath =
      '${AppRoutes.driverModulePath}$performancePath';
}

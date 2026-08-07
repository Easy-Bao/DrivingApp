import 'package:driver_app/src/core/routing/app_routes.dart';

abstract final class DriverLocationRoutes {
  static const String gate = 'DriverLocationGate';
  static const String gatePath = 'location-gate';
  static const String fullGatePath = '${AppRoutes.driverModulePath}$gatePath';
}

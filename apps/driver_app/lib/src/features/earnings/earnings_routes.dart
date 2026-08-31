import 'package:driver_app/src/app/navigation/app_routes.dart';

abstract final class EarningsRoutes {
  static const String earnings = 'Earnings';
  static const String earningsPath = 'earnings';
  static const String fullEarningsPath =
      '${AppRoutes.driverModulePath}$earningsPath';
}

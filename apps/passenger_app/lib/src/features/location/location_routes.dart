import 'package:passenger_app/src/core/routing/app_routes.dart';

abstract final class LocationRoutes {
  static const String gate = 'LocationGate';
  static const String gatePath = 'location-gate';
  static const String fullGatePath =
      '${AppRoutes.passengerModulePath}$gatePath';
}

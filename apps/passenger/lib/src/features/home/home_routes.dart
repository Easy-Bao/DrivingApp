import 'package:passenger/src/app/navigation/app_routes.dart';

abstract final class HomeRoutes {
  static const String home = 'Home';
  static const String homePath = 'home';
  static const String fullHomePath =
      '${AppRoutes.passengerModulePath}$homePath';
}

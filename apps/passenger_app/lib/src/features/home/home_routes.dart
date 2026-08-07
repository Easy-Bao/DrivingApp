import 'package:passenger_app/src/core/routing/app_routes.dart';

abstract final class HomeRoutes {
  static const String home = 'Home';
  static const String homePath = 'home';
  static const String fullHomePath =
      '${AppRoutes.passengerModulePath}$homePath';
  static const String addCategory = 'AddCategory';
  static const String addCategoryPath = 'home/add-category';
}

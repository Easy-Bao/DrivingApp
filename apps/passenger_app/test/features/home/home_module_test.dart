import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/passenger_module.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';

void main() {
  test('registers the saved-place configuration route', () {
    final hasAddCategoryRoute = PassengerModule().routes
        .whereType<ChildRoute>()
        .any((route) => route.name == HomeRoutes.addCategory);

    expect(hasAddCategoryRoute, isTrue);
  });
}

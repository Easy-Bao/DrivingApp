import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/passenger_module.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:passenger_app/src/features/saved_places/saved_places_routes.dart';

void main() {
  test('registers the saved-place configuration route', () {
    final routes = PassengerModule().routes.whereType<ChildRoute>();
    final hasAddCategoryRoute = routes.any(
      (route) => route.name == HomeRoutes.addCategory,
    );
    final hasSavedPlacesRoute = routes.any(
      (route) => route.name == SavedPlacesRoutes.places,
    );

    expect(hasAddCategoryRoute, isTrue);
    expect(hasSavedPlacesRoute, isTrue);
  });
}

import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/app/router.dart';
import 'package:passenger/src/features/saved_places/saved_places_routes.dart';

void main() {
  test('registers the saved-place configuration route', () {
    final routes = AppRouter().routes.whereType<ChildRoute>();
    final addCategoryRoute = routes.firstWhere(
      (route) => route.name == SavedPlacesRoutes.addCategory,
    );
    final hasSavedPlacesRoute = routes.any(
      (route) => route.name == SavedPlacesRoutes.places,
    );

    expect(addCategoryRoute.transitionDuration, AppTransitions.pushDuration);
    expect(hasSavedPlacesRoute, isTrue);
  });
}

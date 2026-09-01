import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/features/profile/profile_module.dart';
import 'package:passenger/src/features/profile/profile_routes.dart';

void main() {
  test('registers the passenger Help Center destination', () {
    final routeNames = ProfileModule.routes.whereType<ChildRoute>().map(
      (route) => route.name,
    );

    expect(routeNames, contains(ProfileRoutes.helpCenter));
  });
}

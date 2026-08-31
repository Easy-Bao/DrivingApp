import 'package:driver_app/src/features/earnings/earnings_module.dart';
import 'package:driver_app/src/features/earnings/earnings_routes.dart';
import 'package:driver_app/src/features/profile/profile_module.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

void main() {
  test('owns the earnings shell route in the earnings feature', () {
    final earningsRouteNames = EarningsModule.shellRoutes
        .whereType<ChildRoute>()
        .map((route) => route.name);
    final profileRouteNames = ProfileModule.routes.whereType<ChildRoute>().map(
      (route) => route.name,
    );

    expect(earningsRouteNames, contains(EarningsRoutes.earnings));
    expect(profileRouteNames, isNot(contains(EarningsRoutes.earnings)));
  });
}

import 'package:driver/src/features/performance/performance_module.dart';
import 'package:driver/src/features/performance/performance_routes.dart';
import 'package:driver/src/features/profile/profile_module.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

void main() {
  test('owns the performance route in the performance feature', () {
    final performanceRouteNames = PerformanceModule.routes
        .whereType<ChildRoute>()
        .map((route) => route.name);
    final profileRouteNames = ProfileModule.routes.whereType<ChildRoute>().map(
      (route) => route.name,
    );

    expect(performanceRouteNames, contains(PerformanceRoutes.performance));
    expect(profileRouteNames, isNot(contains(PerformanceRoutes.performance)));
  });
}

import 'package:driver_app/src/features/activity/activity_module.dart';
import 'package:driver_app/src/features/activity/activity_routes.dart';
import 'package:driver_app/src/features/profile/profile_module.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

void main() {
  test('owns the earnings shell route in the activity feature', () {
    final activityRouteNames = ActivityModule.earningsShellRoutes
        .whereType<ChildRoute>()
        .map((route) => route.name);
    final profileRouteNames = ProfileModule.routes.whereType<ChildRoute>().map(
      (route) => route.name,
    );

    expect(activityRouteNames, contains(ActivityRoutes.earnings));
    expect(profileRouteNames, isNot(contains(ActivityRoutes.earnings)));
  });
}

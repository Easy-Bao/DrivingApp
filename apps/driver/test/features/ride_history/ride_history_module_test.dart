import 'package:driver/src/features/ride_history/ride_history_module.dart';
import 'package:driver/src/features/ride_history/ride_history_routes.dart';
import 'package:driver/src/features/profile/profile_module.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';

void main() {
  test('owns the ride history shell and detail routes', () {
    final shellRouteNames = RideHistoryModule.shellRoutes
        .whereType<ChildRoute>()
        .map((route) => route.name);
    final detailRouteNames = RideHistoryModule.routes
        .whereType<ChildRoute>()
        .map((route) => route.name);
    final profileRouteNames = ProfileModule.routes.whereType<ChildRoute>().map(
      (route) => route.name,
    );

    expect(shellRouteNames, contains(RideHistoryRoutes.tripHistory));
    expect(detailRouteNames, contains(RideHistoryRoutes.tripDetail));
    expect(profileRouteNames, isNot(contains(RideHistoryRoutes.tripHistory)));
    expect(profileRouteNames, isNot(contains(RideHistoryRoutes.tripDetail)));
  });
}

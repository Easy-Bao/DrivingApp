import 'package:flutter_test/flutter_test.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/features/profile/profile_module.dart';
import 'package:passenger/src/features/profile/profile_routes.dart';
import 'package:passenger/src/features/settings/settings_module.dart';
import 'package:passenger/src/features/settings/settings_routes.dart';

void main() {
  test('registers profile info without redundant settings or help routes', () {
    final profileRouteNames = ProfileModule.routes
        .whereType<ChildRoute>()
        .map((route) => route.name)
        .toList();
    final settingsRouteNames = SettingsModule.routes
        .whereType<ChildRoute>()
        .map((route) => route.name)
        .toList();

    expect(profileRouteNames, [ProfileRoutes.profileInfo]);
    expect(settingsRouteNames, [SettingsRoutes.terms]);
  });
}

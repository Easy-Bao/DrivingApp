import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/settings/presentation/screens/settings_screen.dart';
import 'package:passenger_app/src/features/settings/settings_routes.dart';
import 'package:shared_ui/transitions/passenger_transitions.dart';

class SettingsModule {
  SettingsModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: SettingsRoutes.settings,
      'settings',
      child: (context, GoRouterState state) => const SettingsScreen(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [];
}

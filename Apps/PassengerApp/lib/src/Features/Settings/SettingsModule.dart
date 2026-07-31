import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/Features/Settings/Presentation/Screens/SettingsScreen.dart';
import 'package:passenger_app/src/Features/Settings/SettingsRoutes.dart';
import 'package:shared_ui/shared_ui.dart';

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

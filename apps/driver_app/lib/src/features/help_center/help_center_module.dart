import 'package:driver_app/src/features/help_center/help_center_routes.dart';
import 'package:driver_app/src/features/help_center/view/driver_help_center_page.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_ui/shared_ui.dart';

class DriverHelpCenterModule {
  DriverHelpCenterModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: DriverHelpCenterRoutes.helpCenter,
      DriverHelpCenterRoutes.helpCenterPath,
      child: (context, GoRouterState state) => const DriverHelpCenterPage(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];
}

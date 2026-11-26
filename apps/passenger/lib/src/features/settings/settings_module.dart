import 'package:design_system/design_system.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/features/settings/settings_routes.dart';
import 'package:shared_pages/shared_pages.dart';

class SettingsModule._() {
  static List<ModularRoute> routes = [
    ChildRoute(
      name: SettingsRoutes.terms,
      SettingsRoutes.termsPath,
      child: (context, GoRouterState state) =>
          AppTermsOfServicePage(onBack: () => context.pop()),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [];
}

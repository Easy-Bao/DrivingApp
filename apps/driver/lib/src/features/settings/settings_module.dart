import 'package:design_system/design_system.dart';
import 'package:driver/src/features/settings/presentation/pages/terms_of_service_page.dart';
import 'package:driver/src/features/settings/settings_routes.dart';
import 'package:go_router_modular/go_router_modular.dart';

class SettingsModule._() {
  static List<ModularRoute> routes = [
    ChildRoute(
      name: SettingsRoutes.terms,
      SettingsRoutes.termsPath,
      child: (context, GoRouterState state) => const TermsOfServicePage(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];
}

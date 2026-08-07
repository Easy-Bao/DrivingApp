import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/features/profile/profile_routes.dart';
import 'package:driver_app/src/features/profile/view/driver_account_page.dart';
import 'package:driver_app/src/features/activity/view/earnings_page.dart';
import 'package:shared_ui/shared_ui.dart';

class ProfileModule {
  ProfileModule._();

  static List<ModularRoute> routes = [];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: ProfileRoutes.earnings,
      ProfileRoutes.earningsPath,
      child: (context, GoRouterState state) => const DriverEarningsPage(),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
    ChildRoute(
      name: ProfileRoutes.account,
      ProfileRoutes.accountPath,
      child: (context, GoRouterState state) => const DriverAccountPage(),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}

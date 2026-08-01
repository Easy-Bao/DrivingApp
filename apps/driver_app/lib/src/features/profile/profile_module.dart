import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/features/profile/profile_routes.dart';
import 'package:driver_app/src/features/profile/presentation/screens/driver_account.dart';
import 'package:driver_app/src/features/activity/presentation/screens/earnings_screen.dart';
import 'package:shared_ui/shared_ui.dart';

class ProfileModule {
  ProfileModule._();

  static List<ModularRoute> routes = [];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: ProfileRoutes.earnings,
      'earnings',
      child: (context, GoRouterState state) => const DriverEarningsScreen(),
      transition: AppTransitions.fade,
      transitionDuration: AppTransitions.fadeDuration,
    ),
    ChildRoute(
      name: ProfileRoutes.account,
      'account',
      child: (context, GoRouterState state) => const DriverAccountScreen(),
      transition: AppTransitions.fade,
      transitionDuration: AppTransitions.fadeDuration,
    ),
  ];
}

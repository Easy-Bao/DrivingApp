import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/Features/Profile/ProfileRoutes.dart';
import 'package:driver_app/src/Features/Profile/Presentation/Screens/DriverAccount.dart';
import 'package:driver_app/src/Features/Activity/Presentation/Screens/EarningsScreen.dart';
import 'package:shared_ui/SharedUi.dart';

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

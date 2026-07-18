import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/profile/presentation/screens/help_center_screen.dart';
import 'package:passenger_app/src/features/profile/presentation/screens/profile_info_screen.dart';
import 'package:passenger_app/src/features/activity/presentation/screens/ride_history_screen.dart';
import 'package:shared_ui/transitions/passenger_transitions.dart';

class AccountModule {
  AccountModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: 'RideHistory',
      'account/ride-history',
      child: (context, GoRouterState state) => const RideHistoryScreen(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: 'ProfileInfo',
      'account/profile-info',
      child: (context, GoRouterState state) => const ProfileInfoScreen(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: 'HelpCenter',
      'account/help-center',
      child: (context, GoRouterState state) => const HelpCenterScreen(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];
}

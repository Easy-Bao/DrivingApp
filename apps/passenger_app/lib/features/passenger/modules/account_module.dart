/// Account Module: registers routes for passenger profile info, support help, and ride history.
library;
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/core/transitions/app_transitions.dart';
import 'package:passenger_app/features/passenger/presentation/views/account/help_center_screen.dart';
import 'package:passenger_app/features/passenger/presentation/views/account/profile_info_screen.dart';
import 'package:passenger_app/features/passenger/presentation/views/account/ride_history_screen.dart';

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

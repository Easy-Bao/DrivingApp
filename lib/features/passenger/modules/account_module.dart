import 'package:BaoRide/features/passenger/presentation/views/account/help_center_screen.dart';
import 'package:BaoRide/features/passenger/presentation/views/account/profile_info_screen.dart';
import 'package:BaoRide/features/passenger/presentation/views/account/ride_history_screen.dart';
import 'package:BaoRide/features/passenger/presentation/views/account/security_screen.dart';
import 'package:go_router_modular/go_router_modular.dart';

class AccountModule {
  AccountModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: 'RideHistory',
      'account/ride-history',
      child: (context, GoRouterState state) => const RideHistoryScreen(),
      transition: GoTransitions.slide.toLeft,
    ),
    ChildRoute(
      name: 'ProfileInfo',
      'account/profile-info',
      child: (context, GoRouterState state) => const ProfileInfoScreen(),
      transition: GoTransitions.slide.toLeft,
    ),
    ChildRoute(
      name: 'Security',
      'account/security',
      child: (context, GoRouterState state) => const SecurityScreen(),
      transition: GoTransitions.slide.toLeft,
    ),
    ChildRoute(
      name: 'HelpCenter',
      'account/help-center',
      child: (context, GoRouterState state) => const HelpCenterScreen(),
      transition: GoTransitions.slide.toLeft,
    ),
  ];
}

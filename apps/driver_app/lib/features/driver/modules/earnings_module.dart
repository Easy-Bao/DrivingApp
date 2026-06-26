import 'package:driver_app/features/driver/presentation/views/earnings/driver_trip_history_screen.dart';
import 'package:driver_app/features/driver/presentation/views/earnings/earnings_screen.dart';
import 'package:driver_app/core/transitions/app_transitions.dart';
import 'package:go_router_modular/go_router_modular.dart';

class EarningsModule {
  EarningsModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: 'DriverTripHistory',
      'earnings/trip-history',
      child: (context, GoRouterState state) => const DriverTripHistoryScreen(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: 'DriverEarnings',
      'earnings',
      child: (context, GoRouterState state) => const DriverEarningsScreen(),
      transition: AppTransitions.fade,
      transitionDuration: AppTransitions.fadeDuration,
    ),
  ];
}

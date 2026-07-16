import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/trip_booking/modules/account_module.dart';
import 'package:passenger_app/src/features/trip_booking/modules/activity_module.dart';
import 'package:passenger_app/src/features/trip_booking/modules/home_module.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/views/account/help_center_screen.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/views/passenger_account_screen.dart';
import 'package:passenger_app/src/shared/widgets/navigationbar/passenger_tab.dart';
import 'package:shared_ui/shared_ui.dart';

class PassengerModule extends Module {
  final homeRoutes = [...HomeModule.shellRoutes];
  final homeRoutesScreen = [...HomeModule.routes];

  final activityRoutes = [...ActivityModule.shellRoutes];
  final activityRoutesScreen = [...ActivityModule.routes];

  final accountRoutesScreen = [...AccountModule.routes];

  static List<ModularRoute> get route => <ModularRoute>[...HomeModule.routes];

  @override
  List<ModularRoute> get routes => <ModularRoute>[
    // Independent Screen
    ...activityRoutesScreen,
    ...homeRoutesScreen,
    ...accountRoutesScreen,
    ShellModularRoute(
      builder: (context, GoRouterState state, child) =>
          PassengerShellLayout(child: child),
      routes: [
        ...homeRoutes,
        ...activityRoutes,
        ChildRoute(
          name: 'PassengerAccount',
          'account',
          child: (context, GoRouterState state) =>
              const PassengerAccountScreen(),
          transition: AppTransitions.none,
          transitionDuration: Duration.zero,
        ),
        ChildRoute(
          name: 'PassengerHelp',
          'help',
          child: (context, GoRouterState state) =>
              const HelpCenterScreen(),
          transition: AppTransitions.none,
          transitionDuration: Duration.zero,
        ),
      ],
    ),
  ];
}

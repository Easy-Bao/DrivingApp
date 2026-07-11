import 'package:driver_app/src/features/driver_dispatch/modules/dashboard_module.dart';
import 'package:driver_app/src/features/driver_dispatch/modules/earnings_module.dart';
import 'package:driver_app/src/features/driver_dispatch/modules/ride_module.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/views/driver_account.dart';
import 'package:driver_app/src/core/transitions/app_transitions.dart';
import 'package:driver_app/src/shared/widgets/navigationbar/driver_tab.dart';
import 'package:go_router_modular/go_router_modular.dart';

class DriverModule extends Module {
  @override
  List<ModularRoute> get routes => <ModularRoute>[
    ...DashboardModule.routes,
    ...RideModule.routes,
    ...EarningsModule.routes,

    ShellModularRoute(
      builder: (context, GoRouterState state, child) =>
          DriverShellLayout(child: child),
      routes: [
        ...DashboardModule.shellRoutes,
        ...EarningsModule.shellRoutes,
        ChildRoute(
          name: 'DriverAccount',
          'account',
          child: (context, GoRouterState state) => const DriverAccountScreen(),
          transition: AppTransitions.fade,
          transitionDuration: AppTransitions.fadeDuration,
        ),
      ],
    ),
  ];
}

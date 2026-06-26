import 'package:driver_app/features/driver/modules/dashboard_module.dart';
import 'package:driver_app/features/driver/modules/earnings_module.dart';
import 'package:driver_app/features/driver/modules/ride_module.dart';
import 'package:driver_app/features/driver/presentation/views/driver_account.dart';
import 'package:driver_app/core/transitions/app_transitions.dart';
import 'package:driver_app/shared/widgets/navigationbar/driver_tab.dart';
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

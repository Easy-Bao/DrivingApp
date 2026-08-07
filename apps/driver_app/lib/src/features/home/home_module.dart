import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/features/home/home_routes.dart';
import 'package:driver_app/src/features/home/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver_app/src/features/home/view/driver_dashboard_page.dart';
import 'package:shared_ui/shared_ui.dart';

class HomeModule {
  HomeModule._();

  static List<ModularRoute> routes = [];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: HomeRoutes.dashboard,
      HomeRoutes.dashboardPath,
      child: (context, GoRouterState state) => BlocProvider.value(
        value: Modular.get<DashboardCubit>()..initialize(),
        child: const DriverDashboardPage(),
      ),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}

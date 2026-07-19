import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/features/home/home_routes.dart';
import 'package:driver_app/src/features/home/presentation/bloc/dashboard_cubit.dart';
import 'package:driver_app/src/features/home/presentation/screens/driver_dashboard.dart';
import 'package:shared_ui/transitions/driver_transitions.dart';

class HomeModule {
  HomeModule._();

  static List<ModularRoute> routes = [];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: HomeRoutes.dashboard,
      'dashboard',
      child: (context, GoRouterState state) => BlocProvider.value(
        value: Modular.get<DashboardCubit>()..loadStats(),
        child: const DriverDashboardScreen(),
      ),
      transition: AppTransitions.fade,
      transitionDuration: AppTransitions.fadeDuration,
    ),
  ];
}

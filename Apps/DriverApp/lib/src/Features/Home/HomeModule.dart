import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/Features/Home/HomeRoutes.dart';
import 'package:driver_app/src/Features/Home/Presentation/Bloc/DashboardCubit.dart';
import 'package:driver_app/src/Features/Home/Presentation/Screens/DriverDashboard.dart';
import 'package:shared_ui/SharedUi.dart';

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

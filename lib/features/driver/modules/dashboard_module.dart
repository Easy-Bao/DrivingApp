import 'dart:async';

import 'package:BaoRide/core/di/service_locator.dart';
import 'package:BaoRide/features/driver/data/repositories/dashboard_repository.dart';
import 'package:BaoRide/features/driver/presentation/bloc/dashboard/dashboard_cubit.dart';
import 'package:BaoRide/features/driver/presentation/views/dashboard/ride_alert_screen.dart';
import 'package:BaoRide/features/driver/presentation/views/driver_dashboard.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';

class DashboardModule {
  DashboardModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: 'RideAlert',
      'dashboard/ride-alert',
      child: (context, GoRouterState state) => const RideAlertScreen(),
      transition: GoTransitions.fade,
      transitionDuration: const Duration(milliseconds: 200),
    ),
  ];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: 'DriverDashboard',
      'dashboard',
      child: (context, GoRouterState state) => BlocProvider(
        create: (_) {
          // NOTE: getIt<DashboardRepository>() automatically injects the active implementation
          // (MockDashboardRepository, or _ApiDashboardRepository when backend is ready)
          // based on the single configuration line in lib/core/di/service_locator.dart.
          final cubit = DashboardCubit(
            repository: getIt<DashboardRepository>(),
          );
          unawaited(cubit.loadStats());
          return cubit;
        },
        child: const DriverDashboardScreen(),
      ),
      transition: GoTransitions.fade,
    ),
  ];
}

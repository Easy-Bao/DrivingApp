import 'package:driver_app/features/driver/presentation/views/dashboard/driver_chat_screen.dart';
import 'dart:async';

import 'package:driver_app/core/di/service_locator.dart';
import 'package:core_models/core_models.dart';
import 'package:driver_app/core/transitions/app_transitions.dart';
import 'package:driver_app/features/driver/presentation/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver_app/features/driver/presentation/views/dashboard/ride_alert_screen.dart';
import 'package:driver_app/features/driver/presentation/views/driver_dashboard.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';

class DashboardModule {
  DashboardModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: 'RideAlert',
      'dashboard/ride-alert',
      child: (context, GoRouterState state) => RideAlertScreen(
        rideData: state.extra as Map<String, dynamic>?,
      ),
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
    ChildRoute(
      name: 'DriverChat',
      'dashboard/driver-chat',
      child: (context, GoRouterState state) {
        final extra = state.extra as Map<String, dynamic>?;
        return DriverChatScreen(
          roomId: extra?['roomId'] as String?,
          userId: extra?['userId'] as String?,
          peerName: extra?['peerName'] as String?,
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: 'DriverDashboard',
      'dashboard',
      child: (context, GoRouterState state) => BlocProvider(
        create: (_) {
          // NOTE: getIt<DashboardRepository>() automatically injects the active implementation
          // (FixtureDashboardRepository, or _ApiDashboardRepository when backend is ready)
          // based on the single configuration line in lib/core/di/service_locator.dart.
          final cubit = DashboardCubit(
            repository: getIt<DashboardRepository>(),
          );
          unawaited(cubit.loadStats());
          return cubit;
        },
        child: const DriverDashboardScreen(),
      ),
      transition: AppTransitions.fade,
      transitionDuration: AppTransitions.fadeDuration,
    ),
  ];
}

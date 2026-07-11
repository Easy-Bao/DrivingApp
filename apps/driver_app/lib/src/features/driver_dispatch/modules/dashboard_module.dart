import 'package:driver_app/src/features/driver_dispatch/presentation/views/dashboard/driver_chat_screen.dart';

import 'package:driver_app/src/core/di/service_locator.dart';
import 'package:driver_app/src/core/transitions/app_transitions.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/blocs/dashboard/dashboard_cubit.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/views/dashboard/ride_alert_screen.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/views/driver_dashboard.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';

class DashboardModule {
  DashboardModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: 'RideAlert',
      'dashboard/ride-alert',
      child: (context, GoRouterState state) =>
          RideAlertScreen(rideData: state.extra as Map<String, dynamic>?),
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
      child: (context, GoRouterState state) => BlocProvider.value(
        value: getIt<DashboardCubit>()..loadStats(),
        child: const DriverDashboardScreen(),
      ),
      transition: AppTransitions.fade,
      transitionDuration: AppTransitions.fadeDuration,
    ),
  ];
}

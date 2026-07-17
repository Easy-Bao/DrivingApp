import 'package:shared_ui/transitions/driver_transitions.dart';
import 'package:driver_app/src/features/dashboard/presentation/blocs/dashboard/dashboard_cubit.dart';
import 'package:driver_app/src/features/dashboard/presentation/views/driver_account.dart';
import 'package:driver_app/src/features/dashboard/presentation/views/driver_dashboard.dart';
import 'package:driver_app/src/features/dashboard/presentation/views/earnings/driver_trip_detail_screen.dart';
import 'package:driver_app/src/features/dashboard/presentation/views/earnings/driver_trip_history_screen.dart';
import 'package:driver_app/src/features/dashboard/presentation/views/earnings/earnings_screen.dart';
import 'package:driver_app/src/features/driver_dispatch/driver_routes.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/views/dashboard/driver_chat_screen.dart';
import 'package:driver_app/src/features/driver_dispatch/presentation/views/dashboard/ride_alert_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';

class DashboardModule {
  DashboardModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: DriverRoutes.rideAlert,
      'dashboard/ride-alert',
      child: (context, GoRouterState state) =>
          RideAlertScreen(rideData: state.extra as Map<String, dynamic>?),
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
    ChildRoute(
      name: DriverRoutes.driverChat,
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
    ChildRoute(
      name: DriverRoutes.driverTripHistory,
      'earnings/trip-history',
      child: (context, GoRouterState state) => const DriverTripHistoryScreen(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: DriverRoutes.driverTripDetail,
      'earnings/trip-detail',
      child: (context, GoRouterState state) =>
          DriverTripDetailScreen(trip: state.extra as Map<String, dynamic>),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: DriverRoutes.driverDashboard,
      'dashboard',
      child: (context, GoRouterState state) => BlocProvider.value(
        value: Modular.get<DashboardCubit>()..loadStats(),
        child: const DriverDashboardScreen(),
      ),
      transition: AppTransitions.fade,
      transitionDuration: AppTransitions.fadeDuration,
    ),
    ChildRoute(
      name: DriverRoutes.driverEarnings,
      'earnings',
      child: (context, GoRouterState state) => const DriverEarningsScreen(),
      transition: AppTransitions.fade,
      transitionDuration: AppTransitions.fadeDuration,
    ),
    ChildRoute(
      name: DriverRoutes.driverAccount,
      'account',
      child: (context, GoRouterState state) => const DriverAccountScreen(),
      transition: AppTransitions.fade,
      transitionDuration: AppTransitions.fadeDuration,
    ),
  ];
}

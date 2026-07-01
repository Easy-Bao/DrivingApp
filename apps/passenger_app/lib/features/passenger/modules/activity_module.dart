import 'package:core_models/core_models.dart';
import 'package:passenger_app/features/passenger/presentation/views/activity/driver_chat_screen.dart';
import 'package:passenger_app/features/passenger/presentation/views/activity/track_driver.dart';
import 'package:passenger_app/features/passenger/presentation/views/activity/view_details.dart';
import 'package:passenger_app/features/passenger/presentation/views/activity/passenger_rating_screen.dart';
import 'package:passenger_app/features/passenger/presentation/views/passenger_activity.dart';
import 'package:passenger_app/core/transitions/app_transitions.dart';
import 'package:go_router_modular/go_router_modular.dart';

class ActivityModule {
  ActivityModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: 'ActivityViewDetails',
      'activity/viewDetails',
      child: (context, GoRouterState state) {
        final ride = state.extra is RideHistoryModel
            ? state.extra as RideHistoryModel
            : null;
        return ActivityViewDetails(ride: ride);
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: 'ActivityTrackDriver',
      'activity/trackDriver',
      child: (context, GoRouterState state) {
        final ride = state.extra is RideHistoryModel
            ? state.extra as RideHistoryModel
            : null;
        return AcitivityTrackDriver(ride: ride);
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: 'DriverChat',
      'activity/driver-chat',
      child: (context, GoRouterState state) => const DriverChatScreen(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: 'PassengerRating',
      'activity/rating',
      child: (context, GoRouterState state) => const PassengerRatingScreen(),
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: 'PassengerActivity',
      'activity',
      child: (context, GoRouterState state) => const PassengerActivityScreen(),
      transition: AppTransitions.fade,
      transitionDuration: AppTransitions.fadeDuration,
    ),
  ];
}


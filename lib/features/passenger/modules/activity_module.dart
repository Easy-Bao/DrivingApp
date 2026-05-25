import 'package:BaoRide/features/passenger/presentation/views/activity/driver_chat_screen.dart';
import 'package:BaoRide/features/passenger/presentation/views/activity/track_driver.dart';
import 'package:BaoRide/features/passenger/presentation/views/activity/view_details.dart';
import 'package:BaoRide/features/passenger/presentation/views/activity/passenger_rating_screen.dart';
import 'package:BaoRide/features/passenger/presentation/views/passenger_activity.dart';
import 'package:go_router_modular/go_router_modular.dart';

class ActivityModule {
  ActivityModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: 'ActivityViewDetails',
      'activity/viewDetails',
      child: (context, GoRouterState state) => const ActivityViewDetails(),
      transition: GoTransitions.fadeUpwards,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    ChildRoute(
      name: 'ActivityTrackDriver',
      'activity/trackDriver',
      child: (context, GoRouterState state) => const AcitivityTrackDriver(),
      transition: GoTransitions.fadeUpwards,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    ChildRoute(
      name: 'DriverChat',
      'activity/driver-chat',
      child: (context, GoRouterState state) => const DriverChatScreen(),
      transition: GoTransitions.slide.toLeft,
    ),
    ChildRoute(
      name: 'PassengerRating',
      'activity/rating',
      child: (context, GoRouterState state) => const PassengerRatingScreen(),
      transition: GoTransitions.fadeUpwards,
      transitionDuration: const Duration(milliseconds: 400),
    ),
  ];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: 'PassengerActivity',
      'activity',
      child: (context, GoRouterState state) => const PassengerActivityScreen(),
    ),
  ];
}

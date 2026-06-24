import 'package:passenger_app/features/passenger/presentation/views/activity/driver_chat_screen.dart';
import 'package:passenger_app/features/passenger/presentation/views/activity/track_driver.dart';
import 'package:passenger_app/features/passenger/presentation/views/activity/view_details.dart';
import 'package:passenger_app/features/passenger/presentation/views/activity/passenger_rating_screen.dart';
import 'package:passenger_app/features/passenger/presentation/views/passenger_activity.dart';
import 'package:go_router_modular/go_router_modular.dart';

class ActivityModule {
  ActivityModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: 'ActivityViewDetails',
      'activity/viewDetails',
      child: (context, GoRouterState state) => const ActivityViewDetails(),
      transition: GoTransitions.slide.toLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    ChildRoute(
      name: 'ActivityTrackDriver',
      'activity/trackDriver',
      child: (context, GoRouterState state) => const AcitivityTrackDriver(),
      transition: GoTransitions.slide.toLeft,
      transitionDuration: const Duration(milliseconds: 200),
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
      transition: GoTransitions.slide.toLeft,
      transitionDuration: const Duration(milliseconds: 200),
    ),
  ];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: 'PassengerActivity',
      'activity',
      child: (context, GoRouterState state) => const PassengerActivityScreen(),
      transition: GoTransitions.fade,
    ),
  ];
}

import 'package:BaoRide/features/passenger/presentation/views/home/screens/search_destination.dart';
import 'package:BaoRide/features/passenger/presentation/views/home/screens/view_all_suggestions.dart';
import 'package:BaoRide/features/passenger/presentation/views/passenger_home.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:flutter/material.dart';

class HomeModule {
  static List<ModularRoute> routes = [
    ChildRoute(
      name: "SearchDestination",
      "home/search",
      child: (context, state) => const SearchDestinationScreen(),
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const SearchDestinationScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
            child: child,
          );
        },
      ),
    ),
    // ChildRoute(
    //   name: "ViewAllSuggestions",
    //   "home/suggestions",
    //   child: (context, state) => const PassengerViewAllSuggestions(),
    //   pageBuilder: (context, state) => CustomTransitionPage<void>(
    //     key: state.pageKey,
    //     child: const PassengerViewAllSuggestions(),
    //     transitionDuration: const Duration(milliseconds: 400),
    //     transitionsBuilder: (context, animation, secondaryAnimation, child) {
    //       return FadeTransition(
    //         opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
    //         child: child,
    //       );
    //     },
    //   ),
    // ),
    ChildRoute(
      name: "ViewAllSuggestions",
      "home/suggestions",
      child: (context, GoRouterState state) => PassengerViewAllSuggestions(),
      transition: GoTransitions.fadeUpwards,
      transitionDuration: Duration(milliseconds: 300),
    ),
  ];
  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: "PassengerHome",
      "home",
      child: (context, GoRouterState state) => const PassengerHomeScreen(),
    ),
  ];
}

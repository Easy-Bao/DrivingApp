import 'package:BaoRide/core/models/place/place_model.dart';
import 'package:BaoRide/features/passenger/presentation/views/home/screens/activity_detail_map_screen.dart';
import 'package:BaoRide/features/passenger/presentation/views/home/screens/add_category.dart';
import 'package:BaoRide/features/passenger/presentation/views/home/screens/destination_preview_screen.dart';
import 'package:BaoRide/features/passenger/presentation/views/home/screens/driver_matched_screen.dart';
import 'package:BaoRide/features/passenger/presentation/views/home/screens/finding_driver_screen.dart';
import 'package:BaoRide/features/passenger/presentation/views/home/screens/map_pin_screen.dart';
import 'package:BaoRide/features/passenger/presentation/views/home/screens/notification_screen.dart';
import 'package:BaoRide/features/passenger/presentation/views/home/screens/ride_selection_screen.dart';
import 'package:BaoRide/features/passenger/presentation/views/home/screens/search_destination.dart';
import 'package:BaoRide/features/passenger/presentation/views/home/screens/view_all_activity.dart';
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
    ChildRoute(
      name: "ViewAllSuggestions",
      "home/suggestions",
      child: (context, GoRouterState state) => PassengerViewAllActivity(),
      transition: GoTransitions.fadeUpwards,
      transitionDuration: Duration(milliseconds: 300),
    ),
    ChildRoute(
      name: "PassengerAddCategory",
      "home/add-category",
      child: (context, GoRouterState state) =>
          PassengerAddCategoryScreen(onSave: (category) {}),
      transition: GoTransitions.slide.toLeft,
    ),
    ChildRoute(
      name: "Notifications",
      "home/notifications",
      child: (context, GoRouterState state) => const NotificationScreen(),
      transition: GoTransitions.slide.toLeft,
    ),
    ChildRoute(
      name: "ActivityDetailMap",
      "home/activity-detail",
      child: (context, GoRouterState state) {
        final data = state.extra as Map<String, dynamic>;
        return ActivityDetailMapScreen(
          placeName: data["title"] as String,
          placeSubtitle: data["subtitle"] as String,
          destinationLat: (data["lat"] as num).toDouble(),
          destinationLng: (data["lng"] as num).toDouble(),
        );
      },
      transition: GoTransitions.slide.toLeft,
    ),
    ChildRoute(
      name: "MapPin",
      "home/map-pin",
      child: (context, GoRouterState state) => const MapPinScreen(),
      transition: GoTransitions.slide.toLeft,
    ),
    ChildRoute(
      name: "DestinationPreview",
      "home/destination-preview",
      child: (context, GoRouterState state) {
        final place = state.extra as PlaceModel;
        return DestinationPreviewScreen(destination: place);
      },
      transition: GoTransitions.slide.toLeft,
    ),
    ChildRoute(
      name: "RideSelection",
      "home/ride-selection",
      child: (context, GoRouterState state) {
        final data = state.extra as Map<String, dynamic>;
        return RideSelectionScreen(
          destination: data["destination"] as PlaceModel,
          distance: data["distance"] as String,
          duration: data["duration"] as String,
          distanceKm: (data["distanceKm"] as num).toDouble(),
        );
      },
      transition: GoTransitions.slide.toLeft,
    ),
    ChildRoute(
      name: "FindingDriver",
      "home/finding-driver",
      child: (context, GoRouterState state) {
        final data = state.extra as Map<String, dynamic>;
        return FindingDriverScreen(
          rideType: data["rideType"] as String,
          fare: (data["fare"] as num).toDouble(),
          destination: data["destination"] as PlaceModel,
          distance: data["distance"] as String,
          duration: data["duration"] as String,
        );
      },
      transition: GoTransitions.fadeUpwards,
      transitionDuration: Duration(milliseconds: 400),
    ),
    ChildRoute(
      name: "DriverMatched",
      "home/driver-matched",
      child: (context, GoRouterState state) {
        final data = state.extra as Map<String, dynamic>;
        return DriverMatchedScreen(
          rideType: data["rideType"] as String,
          fare: (data["fare"] as num).toDouble(),
          destination: data["destination"] as PlaceModel,
          distance: data["distance"] as String,
          duration: data["duration"] as String,
          driverName: data["driverName"] as String?,
          driverRating: data["driverRating"] as String?,
          vehicleType: data["vehicleType"] as String?,
          plateNumber: data["plateNumber"] as String?,
        );
      },
      transition: GoTransitions.fadeUpwards,
      transitionDuration: const Duration(milliseconds: 400),
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

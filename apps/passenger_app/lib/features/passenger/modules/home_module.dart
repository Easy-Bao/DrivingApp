import 'package:passenger_app/core/di/service_locator.dart';
import 'package:core_models/core_models.dart';
import 'package:passenger_app/core/transitions/app_transitions.dart';
import 'package:passenger_app/features/passenger/presentation/bloc/home/passenger_home_cubit.dart';
import 'package:passenger_app/features/passenger/presentation/views/home/screens/activity_detail_map_screen.dart';
import 'package:passenger_app/features/passenger/presentation/views/home/screens/add_category.dart';
import 'package:passenger_app/features/passenger/presentation/views/home/screens/destination_preview_screen.dart';
import 'package:passenger_app/features/passenger/presentation/views/home/screens/driver_matched_screen.dart';
import 'package:passenger_app/features/passenger/presentation/views/home/screens/finding_driver_screen.dart';
import 'package:passenger_app/features/passenger/presentation/views/home/screens/map_pin_screen.dart';
import 'package:passenger_app/features/passenger/presentation/views/home/screens/notification_screen.dart';
import 'package:passenger_app/features/passenger/presentation/views/home/screens/ride_selection_screen.dart';
import 'package:passenger_app/features/passenger/presentation/views/home/screens/search_destination.dart';
import 'package:passenger_app/features/passenger/presentation/views/home/screens/view_all_activity.dart';
import 'package:passenger_app/features/passenger/presentation/views/passenger_home.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';


class HomeModule {
  HomeModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: 'SearchDestination',
      'home/search',
      child: (context, GoRouterState state) => SearchDestinationScreen(
        preselectedRideType: state.uri.queryParameters['rideType'],
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: 'ViewAllSuggestions',
      'home/suggestions',
      child: (context, GoRouterState state) => PassengerViewAllActivity(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: 'PassengerAddCategory',
      'home/add-category',
      child: (context, GoRouterState state) =>
          PassengerAddCategoryScreen(onSave: (category) {}),
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
    ChildRoute(
      name: 'Notifications',
      'home/notifications',
      child: (context, GoRouterState state) => const NotificationScreen(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: 'ActivityDetailMap',
      'home/activity-detail',
      child: (context, GoRouterState state) {
        final data = state.extra as Map<String, dynamic>;
        return ActivityDetailMapScreen(
          placeName: data['title'] as String,
          placeSubtitle: data['subtitle'] as String,
          destinationLat: (data['lat'] as num).toDouble(),
          destinationLng: (data['lng'] as num).toDouble(),
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: 'MapPin',
      'home/map-pin',
      child: (context, GoRouterState state) => const MapPinScreen(),
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
    ChildRoute(
      name: 'DestinationPreview',
      'home/destination-preview',
      child: (context, GoRouterState state) {
        final place = state.extra as PlaceModel;
        return DestinationPreviewScreen(
          destination: place,
          preselectedRideType: state.uri.queryParameters['rideType'],
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: 'RideSelection',
      'home/ride-selection',
      child: (context, GoRouterState state) {
        final data = state.extra as Map<String, dynamic>;
        return RideSelectionScreen(
          destination: data['destination'] as PlaceModel,
          distance: data['distance'] as String,
          duration: data['duration'] as String,
          distanceKm: (data['distanceKm'] as num).toDouble(),
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: 'FindingDriver',
      'home/finding-driver',
      child: (context, GoRouterState state) {
        final data = state.extra as Map<String, dynamic>;
        return FindingDriverScreen(
          rideType: data['rideType'] as String,
          fare: (data['fare'] as num).toDouble(),
          destination: data['destination'] as PlaceModel,
          distance: data['distance'] as String,
          duration: data['duration'] as String,
        );
      },
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
    ChildRoute(
      name: 'DriverMatched',
      'home/driver-matched',
      child: (context, GoRouterState state) {
        final data = state.extra as Map<String, dynamic>;
        return DriverMatchedScreen(
          rideType: data['rideType'] as String,
          fare: (data['fare'] as num).toDouble(),
          destination: data['destination'] as PlaceModel,
          distance: data['distance'] as String,
          duration: data['duration'] as String,
          driverName: data['driverName'] as String?,
          driverRating: data['driverRating'] as String?,
          vehicleType: data['vehicleType'] as String?,
          plateNumber: data['plateNumber'] as String?,
        );
      },
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: 'PassengerHome',
      'home',
      child: (context, GoRouterState state) => BlocProvider(
        create: (_) {
          // NOTE: getIt<PassengerHomeRepository>() automatically injects the active implementation
          // (FixturePassengerHomeRepository, or _ApiPassengerHomeRepository when backend is ready)
          // based on the single configuration line in lib/core/di/service_locator.dart.
          return PassengerHomeCubit(
            repository: getIt<PassengerHomeRepository>(),
          );
        },
        child: const PassengerHomeScreen(),
      ),
      transition: AppTransitions.fade,
      transitionDuration: AppTransitions.fadeDuration,
    ),
  ];
}

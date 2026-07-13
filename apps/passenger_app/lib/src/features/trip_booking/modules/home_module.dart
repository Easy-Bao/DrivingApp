import 'package:core_models/core_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/di/service_locator.dart';
import 'package:passenger_app/src/core/transitions/app_transitions.dart';
import 'package:passenger_app/src/features/trip_booking/domain/entities/saved_place.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/home/passenger_home_cubit.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/home/saved_places_cubit.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/views/home/screens/activity_detail_map_screen.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/views/home/screens/add_category.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/views/home/screens/destination_preview_screen.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/views/home/screens/driver_matched_screen.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/views/home/screens/finding_driver_screen.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/views/home/screens/map_pin_screen.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/views/home/screens/notification_screen.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/views/home/screens/ride_selection_screen.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/views/home/screens/search_destination.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/views/home/screens/view_all_activity.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/views/passenger_home.dart';

class HomeModule {
  HomeModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: 'SearchDestination',
      'home/search',
      child: (context, GoRouterState state) => SearchDestinationScreen(
        preselectedRideType: state.uri.queryParameters['rideType'],
        pickupAddress: state.uri.queryParameters['pickupAddress'],
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: 'ViewAllSuggestions',
      'home/suggestions',
      child: (context, GoRouterState state) => const PassengerViewAllActivity(),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: 'PassengerAddCategory',
      'home/add-category',
      child: (context, GoRouterState state) {
        final extra = state.extra as Map<String, dynamic>?;
        final onSave = extra?['onSave'] as Function(SavedPlace)?;
        final place = extra?['place'] as PlaceModel?;
        return PassengerAddCategoryScreen(
          onSave: onSave ?? (_) {},
          initialPlace: place,
        );
      },
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
          pickupAddress: state.uri.queryParameters['pickupAddress'],
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
          fares: data['fares'] as Map<String, double>?,
          pickupAddress: data['pickupAddress'] as String?,
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
          pickupAddress: data['pickupAddress'] as String?,
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
          driverId: data['driverId'] as String?,
          driverName: data['driverName'] as String?,
          driverRating: data['driverRating'] as String?,
          vehicleType: data['vehicleType'] as String?,
          plateNumber: data['plateNumber'] as String?,
          pickupAddress: data['pickupAddress'] as String?,
          createdRide: data['createdRide'] as RideHistoryModel?,
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
      child: (context, GoRouterState state) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) {
              return PassengerHomeCubit(
                repository: getIt<PassengerHomeRepository>(),
              );
            },
          ),
          BlocProvider(create: (_) => getIt<SavedPlacesCubit>()),
        ],
        child: const PassengerHomeScreen(),
      ),
      transition: AppTransitions.fade,
      transitionDuration: AppTransitions.fadeDuration,
    ),
  ];
}

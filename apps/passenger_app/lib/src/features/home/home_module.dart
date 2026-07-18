import 'package:core_models/core_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger_app/src/features/home/presentation/bloc/passenger_home_cubit.dart';
import 'package:passenger_app/src/features/saved_places/presentation/bloc/saved_places_cubit.dart';
import 'package:passenger_app/src/features/booking/presentation/screens/activity_detail_map_screen.dart';
import 'package:passenger_app/src/features/saved_places/presentation/screens/add_category_screen.dart';
import 'package:passenger_app/src/features/booking/presentation/screens/destination_preview_screen.dart';
import 'package:passenger_app/src/features/booking/presentation/screens/driver_matched_screen.dart';
import 'package:passenger_app/src/features/booking/presentation/screens/finding_driver_screen.dart';
import 'package:passenger_app/src/features/booking/presentation/screens/map_pin_screen.dart';
import 'package:passenger_app/src/features/home/presentation/screens/notification_screen.dart';
import 'package:passenger_app/src/features/booking/presentation/screens/ride_selection_screen.dart';
import 'package:passenger_app/src/features/booking/presentation/screens/search_destination_screen.dart';
import 'package:passenger_app/src/features/home/presentation/screens/view_all_activity_screen.dart';
import 'package:passenger_app/src/features/home/presentation/screens/passenger_home_screen.dart';
import 'package:shared_ui/transitions/passenger_transitions.dart';

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
      child: (context, GoRouterState state) =>
          const PassengerViewAllActivityScreen(),
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
                repository: Modular.get<PassengerHomeRepository>(),
              );
            },
          ),
          BlocProvider(create: (_) => Modular.get<SavedPlacesCubit>()),
        ],
        child: const PassengerHomeScreen(),
      ),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}

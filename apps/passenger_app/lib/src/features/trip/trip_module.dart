import 'package:core_models/core_models.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/trip/presentation/screens/activity_detail_map_screen.dart';
import 'package:passenger_app/src/features/trip/presentation/screens/destination_preview_screen.dart';
import 'package:passenger_app/src/features/trip/presentation/screens/driver_matched_screen.dart';
import 'package:passenger_app/src/features/trip/presentation/screens/finding_driver_screen.dart';
import 'package:passenger_app/src/features/trip/presentation/screens/map_pin_screen.dart';
import 'package:passenger_app/src/features/trip/presentation/screens/ride_selection_screen.dart';
import 'package:passenger_app/src/features/trip/presentation/screens/search_destination_screen.dart';
import 'package:passenger_app/src/features/trip/trip_routes.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_ui/transitions/passenger_transitions.dart';

class TripModule {
  TripModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: TripRoutes.searchDestination,
      'home/search',
      child: (context, GoRouterState state) => SearchDestinationScreen(
        preselectedRideType: state.uri.queryParameters['rideType'],
        pickupAddress: state.uri.queryParameters['pickupAddress'],
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: TripRoutes.activityDetailMap,
      'home/activity-detail',
      child: (context, GoRouterState state) {
        final data = SafeRouteExtra.asMap(state.extra);
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
      name: TripRoutes.mapPin,
      'home/map-pin',
      child: (context, GoRouterState state) => const MapPinScreen(),
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
    ChildRoute(
      name: TripRoutes.destinationPreview,
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
      name: TripRoutes.rideSelection,
      'home/ride-selection',
      child: (context, GoRouterState state) {
        final data = SafeRouteExtra.asMap(state.extra);
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
      name: TripRoutes.findingDriver,
      'home/finding-driver',
      child: (context, GoRouterState state) {
        final data = SafeRouteExtra.asMap(state.extra);
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
      name: TripRoutes.driverMatched,
      'home/driver-matched',
      child: (context, GoRouterState state) {
        final data = SafeRouteExtra.asMap(state.extra);
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

  static List<ModularRoute> shellRoutes = [];
}

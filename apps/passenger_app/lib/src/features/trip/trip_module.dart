import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/trip/presentation/screens/activity_detail_map_screen.dart';
import 'package:passenger_app/src/features/trip/presentation/screens/destination_preview_screen.dart';
import 'package:passenger_app/src/features/trip/presentation/screens/driver_matched_screen.dart';
import 'package:passenger_app/src/features/trip/presentation/screens/finding_driver_screen.dart';
import 'package:passenger_app/src/features/trip/presentation/screens/map_pin_screen.dart';
import 'package:passenger_app/src/features/trip/presentation/screens/ride_selection_screen.dart';
import 'package:passenger_app/src/features/trip/presentation/screens/search_destination_screen.dart';
import 'package:passenger_app/src/features/trip/trip_routes.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

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
        final latitude = (data['lat'] as num?)?.toDouble();
        final longitude = (data['lng'] as num?)?.toDouble();
        if (latitude == null || longitude == null) {
          return const Scaffold(
            body: Center(child: Text('Location data is unavailable.')),
          );
        }
        return ActivityDetailMapScreen(
          placeName: data['title'] as String? ?? 'Location',
          placeSubtitle: data['subtitle'] as String? ?? '',
          destinationLat: latitude,
          destinationLng: longitude,
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
        PlaceModel? place;
        if (state.extra is PlaceModel) {
          place = state.extra as PlaceModel;
        } else if (state.extra is Map) {
          final map = state.extra as Map;
          if (map['destination'] is PlaceModel) {
            place = map['destination'] as PlaceModel;
          }
        }

        if (place == null) {
          final name = state.uri.queryParameters['destinationName'];
          final latitude = double.tryParse(
            state.uri.queryParameters['destinationLat'] ?? '',
          );
          final longitude = double.tryParse(
            state.uri.queryParameters['destinationLng'] ?? '',
          );
          if (name == null ||
              name.trim().isEmpty ||
              latitude == null ||
              longitude == null) {
            return const Scaffold(
              body: Center(child: Text('Destination data is unavailable.')),
            );
          }
          place = PlaceModel(
            id: state.uri.queryParameters['destinationId'] ?? name,
            name: name,
            fullAddress:
                state.uri.queryParameters['destinationAddress'] ?? name,
            latitude: latitude,
            longitude: longitude,
          );
        }

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
        final destination = data['destination'] is PlaceModel
            ? data['destination'] as PlaceModel
            : null;
        final distanceKm =
            (data['distanceKm'] as num?)?.toDouble() ??
            double.tryParse(state.uri.queryParameters['distanceKm'] ?? '');
        final distance =
            data['distance'] as String? ??
            state.uri.queryParameters['distance'];
        final duration =
            data['duration'] as String? ??
            state.uri.queryParameters['duration'];
        if (destination == null ||
            distanceKm == null ||
            distance == null ||
            duration == null) {
          return const Scaffold(
            body: Center(child: Text('Trip route data is unavailable.')),
          );
        }
        return RideSelectionScreen(
          destination: destination,
          distance: distance,
          duration: duration,
          distanceKm: distanceKm,
          pickupAddress:
              data['pickupAddress'] as String? ??
              state.uri.queryParameters['pickupAddress'],
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
        final destination = data['destination'];
        if (destination is! PlaceModel) {
          return const Scaffold(
            body: Center(child: Text('Destination data is unavailable.')),
          );
        }
        final fare = (data['fare'] as num?)?.toDouble();
        final distance = data['distance'] as String?;
        final duration = data['duration'] as String?;
        if (fare == null || fare <= 0 || distance == null || duration == null) {
          return const Scaffold(
            body: Center(child: Text('Fare and trip data are unavailable.')),
          );
        }
        return FindingDriverScreen(
          rideType: data['rideType'] as String? ?? 'Solo Ride',
          fare: fare,
          destination: destination,
          distance: distance,
          duration: duration,
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
        final destination = data['destination'];
        if (destination is! PlaceModel) {
          return const Scaffold(
            body: Center(child: Text('Destination data is unavailable.')),
          );
        }
        final fare = (data['fare'] as num?)?.toDouble();
        final distance = data['distance'] as String?;
        final duration = data['duration'] as String?;
        if (fare == null || fare <= 0 || distance == null || duration == null) {
          return const Scaffold(
            body: Center(child: Text('Fare and trip data are unavailable.')),
          );
        }
        return DriverMatchedScreen(
          rideType: data['rideType'] as String? ?? 'Solo Ride',
          fare: fare,
          destination: destination,
          distance: distance,
          duration: duration,
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

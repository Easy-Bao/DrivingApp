import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/trip/bloc/booking/booking_bloc.dart';
import 'package:passenger_app/src/features/trip/trip_routes.dart';
import 'package:passenger_app/src/features/trip/view/activity_detail_map_page.dart';
import 'package:passenger_app/src/features/trip/view/destination_preview_page.dart';
import 'package:passenger_app/src/features/trip/view/driver_matched_page.dart';
import 'package:passenger_app/src/features/trip/view/finding_driver_page.dart';
import 'package:passenger_app/src/features/trip/view/map_pin_page.dart';
import 'package:passenger_app/src/features/trip/view/ride_selection_page.dart';
import 'package:passenger_app/src/features/trip/view/search_destination_page.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

class TripModule {
  TripModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: TripRoutes.searchDestination,
      TripRoutes.searchDestinationPath,
      child: (context, GoRouterState state) => SearchDestinationPage(
        preselectedRideType: state.uri.queryParameters['rideType'],
        pickupAddress: state.uri.queryParameters['pickupAddress'],
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: TripRoutes.activityDetailMap,
      TripRoutes.activityDetailMapPath,
      child: (context, GoRouterState state) {
        final data = SafeRouteExtra.asMap(state.extra);
        final latitude = (data['lat'] as num?)?.toDouble();
        final longitude = (data['lng'] as num?)?.toDouble();
        if (latitude == null || longitude == null) {
          return const Scaffold(
            body: Center(child: Text('Location data is unavailable.')),
          );
        }
        return ActivityDetailMapPage(
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
      TripRoutes.mapPinPath,
      child: (context, GoRouterState state) => const MapPinPage(),
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
    ChildRoute(
      name: TripRoutes.destinationPreview,
      TripRoutes.destinationPreviewPath,
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

        return DestinationPreviewPage(
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
      TripRoutes.rideSelectionPath,
      child: (context, GoRouterState state) {
        final data = SafeRouteExtra.asMap(state.extra);
        final destination = data['destination'] is PlaceModel
            ? data['destination'] as PlaceModel
            : _destinationFromQuery(state.uri.queryParameters);
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
        return BlocProvider<BookingBloc>.value(
          value: Modular.get<BookingBloc>(),
          child: RideSelectionPage(
            destination: destination,
            distance: distance,
            duration: duration,
            distanceKm: distanceKm,
            pickupAddress:
                data['pickupAddress'] as String? ??
                state.uri.queryParameters['pickupAddress'],
          ),
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: TripRoutes.findingDriver,
      TripRoutes.findingDriverPath,
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
        return FindingDriverPage(
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
      TripRoutes.driverMatchedPath,
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
        return DriverMatchedPage(
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

  static PlaceModel? _destinationFromQuery(Map<String, String> parameters) {
    final name = parameters['destinationName'];
    final latitude = double.tryParse(parameters['destinationLat'] ?? '');
    final longitude = double.tryParse(parameters['destinationLng'] ?? '');

    if (name == null ||
        name.trim().isEmpty ||
        latitude == null ||
        longitude == null) {
      return null;
    }

    return PlaceModel(
      id: parameters['destinationId'] ?? name,
      name: name,
      fullAddress: parameters['destinationAddress'] ?? name,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

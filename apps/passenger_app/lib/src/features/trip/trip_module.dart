import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/trip/bloc/booking/booking_bloc.dart';
import 'package:passenger_app/src/features/trip/trip_routes.dart';
import 'package:passenger_app/src/features/trip/view/activity_detail_map_page.dart';
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
        final latitude = _asDouble(data['lat']);
        final longitude = _asDouble(data['lng']);
        if (latitude == null || longitude == null) {
          return const Scaffold(
            body: Center(child: Text('Location data is unavailable.')),
          );
        }
        return ActivityDetailMapPage(
          placeName: _asString(data['title']) ?? 'Location',
          placeSubtitle: _asString(data['subtitle']) ?? '',
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
      name: TripRoutes.rideSelection,
      TripRoutes.rideSelectionPath,
      child: (context, GoRouterState state) {
        final extra = state.extra;
        final data = SafeRouteExtra.asMap(state.extra);
        final destination = extra is PlaceModel
            ? extra
            : data['destination'] is PlaceModel
            ? data['destination'] as PlaceModel
            : _destinationFromQuery(state.uri.queryParameters);
        final distanceKm =
            _asDouble(data['distanceKm']) ??
            double.tryParse(state.uri.queryParameters['distanceKm'] ?? '');
        final distance =
            _asString(data['distance']) ??
            state.uri.queryParameters['distance'];
        final duration =
            _asString(data['duration']) ??
            state.uri.queryParameters['duration'];
        if (destination == null) {
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
            rideType:
                _asString(data['rideType']) ??
                state.uri.queryParameters['rideType'] ??
                'solo',
            initialTipAmount:
                _asInt(data['tipAmount']) ??
                int.tryParse(state.uri.queryParameters['tipAmount'] ?? '') ??
                0,
            initialNotes:
                _asString(data['notes']) ??
                state.uri.queryParameters['notes'] ??
                '',
            pickupLatitude:
                _asDouble(data['pickupLat']) ??
                double.tryParse(state.uri.queryParameters['pickupLat'] ?? ''),
            pickupLongitude:
                _asDouble(data['pickupLng']) ??
                double.tryParse(state.uri.queryParameters['pickupLng'] ?? ''),
            pickupAddress:
                _asString(data['pickupAddress']) ??
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
        final fare = _asDouble(data['fare']);
        final distance = _asString(data['distance']);
        final duration = _asString(data['duration']);
        if (fare == null || fare <= 0 || distance == null || duration == null) {
          return const Scaffold(
            body: Center(child: Text('Fare and trip data are unavailable.')),
          );
        }
        return FindingDriverPage(
          rideType: _asString(data['rideType']) ?? 'Solo Ride',
          fare: fare,
          destination: destination,
          distance: distance,
          duration: duration,
          pickupLatitude: _asDouble(data['pickupLat']),
          pickupLongitude: _asDouble(data['pickupLng']),
          pickupAddress: _asString(data['pickupAddress']),
          passengerNote: _asString(data['passengerNote']) ?? '',
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
        final fare = _asDouble(data['fare']);
        final distance = _asString(data['distance']);
        final duration = _asString(data['duration']);
        if (fare == null || fare <= 0 || distance == null || duration == null) {
          return const Scaffold(
            body: Center(child: Text('Fare and trip data are unavailable.')),
          );
        }
        return DriverMatchedPage(
          rideType: _asString(data['rideType']) ?? 'Solo Ride',
          fare: fare,
          destination: destination,
          distance: distance,
          duration: duration,
          driverId: _asString(data['driverId']),
          driverName: _asString(data['driverName']),
          driverRating: _asString(data['driverRating']),
          vehicleType: _asString(data['vehicleType']),
          plateNumber: _asString(data['plateNumber']),
          pickupAddress: _asString(data['pickupAddress']),
          createdRide: data['createdRide'] is RideHistoryModel
              ? data['createdRide'] as RideHistoryModel
              : null,
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

  static String? _asString(Object? value) {
    if (value is! String) return null;
    final result = value.trim();
    return result.isEmpty ? null : result;
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return value is String ? double.tryParse(value) : null;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return value is String ? int.tryParse(value) : null;
  }
}

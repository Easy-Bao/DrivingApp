import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

import 'package:driver_app/src/features/trip/trip_routes.dart';
import 'package:driver_app/src/features/trip/view/pickup_navigation_page.dart';
import 'package:driver_app/src/features/trip/view/fare_summary_page.dart';
import 'package:driver_app/src/features/trip/view/in_transit_page.dart';
import 'package:driver_app/src/features/trip/view/waiting_passenger_page.dart';
import 'package:shared_ui/shared_ui.dart';

class TripModule {
  TripModule._();

  static List<ModularRoute> routes = [
    ChildRoute(
      name: TripRoutes.pickupNavigation,
      TripRoutes.pickupNavigationPath,
      child: (context, GoRouterState state) {
        final data = _DriverTripRouteData.tryParse(
          SafeRouteExtra.asMap(state.extra),
        );
        if (data == null) return _tripDataUnavailable();
        return PickupNavigationPage(
          pickup: data.pickup,
          dropoff: data.dropoff,
          distance: data.distance,
          fare: data.fare,
          duration: data.duration,
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: TripRoutes.waitingPassenger,
      TripRoutes.waitingPassengerPath,
      child: (context, GoRouterState state) {
        final data = _DriverTripRouteData.tryParse(
          SafeRouteExtra.asMap(state.extra),
        );
        if (data == null) return _tripDataUnavailable();
        return WaitingPassengerPage(
          pickup: data.pickup,
          dropoff: data.dropoff,
          distance: data.distance,
          fare: data.fare,
          duration: data.duration,
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: TripRoutes.inTransit,
      TripRoutes.inTransitPath,
      child: (context, GoRouterState state) {
        final data = _DriverTripRouteData.tryParse(
          SafeRouteExtra.asMap(state.extra),
        );
        if (data == null) return _tripDataUnavailable();
        return InTransitPage(
          pickup: data.pickup,
          dropoff: data.dropoff,
          distance: data.distance,
          fare: data.fare,
          duration: data.duration,
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: TripRoutes.fareSummary,
      TripRoutes.fareSummaryPath,
      child: (context, GoRouterState state) {
        final data = _DriverTripRouteData.tryParse(
          SafeRouteExtra.asMap(state.extra),
        );
        if (data == null) return _tripDataUnavailable();
        return FareSummaryPage(
          pickup: data.pickup,
          dropoff: data.dropoff,
          distance: data.distance,
          fare: data.fare,
          duration: data.duration,
        );
      },
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [];
}

class _DriverTripRouteData {
  const _DriverTripRouteData({
    required this.pickup,
    required this.dropoff,
    required this.distance,
    required this.fare,
    required this.duration,
  });

  final String pickup;
  final String dropoff;
  final double distance;
  final double fare;
  final String duration;

  static _DriverTripRouteData? tryParse(Map<String, dynamic> data) {
    final pickup = _asNonEmptyString(data['pickup']);
    final dropoff = _asNonEmptyString(data['dropoff']);
    final distance = _asDouble(data['distance']);
    final fare = _asDouble(data['fare']);
    final duration = _asNonEmptyString(data['duration']);
    if (pickup == null ||
        dropoff == null ||
        distance == null ||
        fare == null ||
        duration == null ||
        !distance.isFinite ||
        distance < 0 ||
        !fare.isFinite ||
        fare < 0) {
      return null;
    }
    return _DriverTripRouteData(
      pickup: pickup,
      dropoff: dropoff,
      distance: distance,
      fare: fare,
      duration: duration,
    );
  }
}

String? _asNonEmptyString(Object? value) {
  if (value is! String) return null;
  final result = value.trim();
  return result.isEmpty ? null : result;
}

double? _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return value is String ? double.tryParse(value) : null;
}

Widget _tripDataUnavailable() => const Scaffold(
  body: Center(
    child: Text('Trip details are unavailable. Please return and try again.'),
  ),
);

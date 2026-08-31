import 'package:driver_app/src/features/chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';

import 'package:driver_app/src/infrastructure/session/driver_session_store.dart';
import 'package:driver_app/src/features/active_ride/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:driver_app/src/features/active_ride/domain/repositories/driver_ride_repository.dart';
import 'package:driver_app/src/features/active_ride/active_ride_routes.dart';
import 'package:driver_app/src/features/active_ride/presentation/view/pickup_navigation_page.dart';
import 'package:driver_app/src/features/active_ride/presentation/view/fare_summary_page.dart';
import 'package:driver_app/src/features/active_ride/presentation/view/in_transit_page.dart';
import 'package:driver_app/src/features/active_ride/presentation/view/waiting_passenger_page.dart';
import 'package:foundation/foundation.dart';
import 'package:design_system/design_system.dart';

class ActiveRideModule {
  ActiveRideModule._();

  static void binds(Injector i) {
    i.addFactory<LiveMapBloc>(
      (i) => LiveMapBloc(rideRepository: i.get<DriverRideRepository>()),
    );
  }

  static List<ModularRoute> routes = [
    ChildRoute(
      name: ActiveRideRoutes.pickupNavigation,
      ActiveRideRoutes.pickupNavigationPath,
      child: (context, GoRouterState state) {
        final data = _DriverTripRouteData.tryParse(
          RoutePayload.from(extra: state.extra),
        );
        if (data == null) return _tripDataUnavailable();
        return PickupNavigationPage(
          pickup: data.pickup,
          dropoff: data.dropoff,
          distance: data.distance,
          fare: data.fare,
          duration: data.duration,
          rideRepository: Modular.get<DriverRideRepository>(),
          chatRepositoryFactory: Modular.get<ChatRepositoryFactory>(),
          sessionService: Modular.get<DriverSessionStore>(),
          lifecycleCoordinator: Modular.get<AppLifecycleCoordinator>(),
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: ActiveRideRoutes.waitingPassenger,
      ActiveRideRoutes.waitingPassengerPath,
      child: (context, GoRouterState state) {
        final data = _DriverTripRouteData.tryParse(
          RoutePayload.from(extra: state.extra),
        );
        if (data == null) return _tripDataUnavailable();
        return WaitingPassengerPage(
          pickup: data.pickup,
          dropoff: data.dropoff,
          distance: data.distance,
          fare: data.fare,
          duration: data.duration,
          rideRepository: Modular.get<DriverRideRepository>(),
          chatRepositoryFactory: Modular.get<ChatRepositoryFactory>(),
          sessionService: Modular.get<DriverSessionStore>(),
          lifecycleCoordinator: Modular.get<AppLifecycleCoordinator>(),
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: ActiveRideRoutes.inTransit,
      ActiveRideRoutes.inTransitPath,
      child: (context, GoRouterState state) {
        final data = _DriverTripRouteData.tryParse(
          RoutePayload.from(extra: state.extra),
        );
        if (data == null) return _tripDataUnavailable();
        return InTransitPage(
          pickup: data.pickup,
          dropoff: data.dropoff,
          distance: data.distance,
          fare: data.fare,
          duration: data.duration,
          rideRepository: Modular.get<DriverRideRepository>(),
          lifecycleCoordinator: Modular.get<AppLifecycleCoordinator>(),
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: ActiveRideRoutes.fareSummary,
      ActiveRideRoutes.fareSummaryPath,
      child: (context, GoRouterState state) {
        final data = _DriverTripRouteData.tryParse(
          RoutePayload.from(extra: state.extra),
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

  static _DriverTripRouteData? tryParse(RoutePayload data) {
    final pickup = data.string('pickup');
    final dropoff = data.string('dropoff');
    final distance = data.doubleValue('distance');
    final fare = data.doubleValue('fare');
    final duration = data.string('duration');
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

Widget _tripDataUnavailable() => const Scaffold(
  body: Center(
    child: Text('Trip details are unavailable. Please return and try again.'),
  ),
);

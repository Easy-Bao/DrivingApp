import 'package:driver/src/features/active_ride/presentation/view/driver_trip_page.dart';
import 'package:driver/src/features/chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/active_ride_routes.dart';
import 'package:driver/src/features/active_ride/domain/repositories/driver_ride_repository.dart';
import 'package:driver/src/features/active_ride/domain/services/ride_payment_completion_handler.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:driver/src/features/active_ride/presentation/view/fare_summary_page.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:foundation/foundation.dart';

class ActiveRideModule._() {
  static void binds(Injector i) {
    i.addFactory<LiveMapBloc>(
      (i) => LiveMapBloc(rideRepository: i.get<RideRepository>()),
    );
  }

  static List<ModularRoute> routes = [
    ChildRoute(
      name: ActiveRideRoutes.trip,
      ActiveRideRoutes.tripPath,
      child: (context, GoRouterState state) {
        final data = _TripRouteData.tryParse(
          RoutePayload.from(extra: state.extra),
        );
        if (data == null) return _tripDataUnavailable();
        return BlocProvider<LiveMapBloc>(
          create: (_) => Modular.get<LiveMapBloc>(),
          child: DriverTripPage(
            pickup: data.pickup,
            dropoff: data.dropoff,
            distance: data.distance,
            fare: data.fare,
            duration: data.duration,
            chatRepositoryFactory: Modular.get<ChatRepositoryFactory>(),
            sessionService: Modular.get<SessionStore>(),
            lifecycleCoordinator: Modular.get<AppLifecycleCoordinator>(),
          ),
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: ActiveRideRoutes.fareSummary,
      ActiveRideRoutes.fareSummaryPath,
      child: (context, GoRouterState state) {
        final data = _TripRouteData.tryParse(
          RoutePayload.from(extra: state.extra),
        );
        if (data == null) return _tripDataUnavailable();
        return FareSummaryPage(
          pickup: data.pickup,
          dropoff: data.dropoff,
          distance: data.distance,
          fare: data.fare,
          duration: data.duration,
          rideId: data.rideId,
          bookingReference: data.bookingReference,
          rideRepository: Modular.get<RideRepository>(),
          ridePaymentCompletionHandler:
              Modular.get<RidePaymentCompletionHandler>(),
        );
      },
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [];
}

class const _TripRouteData({
  required this.pickup,
  required this.dropoff,
  required this.distance,
  required this.fare,
  required this.duration,
  this.rideId,
  this.bookingReference = '',
}) {
  final String pickup;
  final String dropoff;
  final double distance;
  final double fare;
  final String duration;
  final String? rideId;
  final String bookingReference;

  static _TripRouteData? tryParse(RoutePayload data) {
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
    return _TripRouteData(
      pickup: pickup,
      dropoff: dropoff,
      distance: distance,
      fare: fare,
      duration: duration,
      rideId: data.string('rideId'),
      bookingReference: data.string('bookingReference') ?? '',
    );
  }
}

Widget _tripDataUnavailable() => const Scaffold(
  body: Center(
    child: Text("Trip details aren't available. Go back and try again."),
  ),
);

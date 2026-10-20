import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/core/location/live_map_bloc.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/active_ride_routes.dart';
import 'package:passenger/src/features/active_ride/data/datasources/ride_remote_data_source.dart';
import 'package:passenger/src/features/active_ride/data/repositories/track_repository_impl.dart';
import 'package:passenger/src/features/active_ride/domain/entities/ride_snapshot.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/active_ride/presentation/pages/driver_matched_page.dart';
import 'package:passenger/src/features/active_ride/presentation/pages/payment_page.dart';
import 'package:passenger/src/features/active_ride/presentation/pages/track_driver_page.dart';
import 'package:passenger/src/features/active_ride/presentation/pages/track_driver_page_loader.dart';
import 'package:passenger/src/features/chat/chat.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';

class ActiveRideModule._() {
  static void binds(Injector i) {
    i
      ..addLazySingleton<RideRemoteDataSource>(
        (i) => RideRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<TrackRepository>(
        (i) => TrackRepositoryImpl(
          remoteDataSource: i.get<RideRemoteDataSource>(),
        ),
      );
  }

  static List<ModularRoute> routes({
    required VoidCallback onRideTerminated,
  }) => [
    ChildRoute(
      name: ActiveRideRoutes.driverMatched,
      ActiveRideRoutes.driverMatchedPath,
      child: (context, GoRouterState state) {
        final data = RoutePayload.from(extra: state.extra);
        final destination = data.object<Place>('destination');
        if (destination == null) {
          return const Scaffold(
            body: Center(child: Text('Destination data is unavailable.')),
          );
        }
        final fare = data.doubleValue('fare');
        final distance = data.string('distance');
        final duration = data.string('duration');
        if (fare == null || fare <= 0 || distance == null || duration == null) {
          return const Scaffold(
            body: Center(child: Text('Fare and trip data are unavailable.')),
          );
        }
        return DriverMatchedPage(
          fare: fare,
          destination: destination,
          distance: distance,
          duration: duration,
          driverId: data.string('driverId'),
          driverName: data.string('driverName'),
          driverRating: data.string('driverRating'),
          vehicleType: data.string('vehicleType'),
          plateNumber: data.string('plateNumber'),
          pickupAddress: data.string('pickupAddress'),
          pickupLatitude: data.doubleValue('pickupLatitude'),
          pickupLongitude: data.doubleValue('pickupLongitude'),
          rideId: data.string('rideId'),
          profileRepository: Modular.get<DriverProfileRepository>(),
        );
      },
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
    ChildRoute(
      name: ActiveRideRoutes.trackDriver,
      ActiveRideRoutes.trackDriverPath,
      child: (context, GoRouterState state) {
        final extra = state.extra;
        final ride = switch (extra) {
          final RideSnapshot snapshot => snapshot,
          final Map payload => RideSnapshot.fromJson(
            Map<String, dynamic>.from(payload),
          ),
          _ => null,
        };
        if (ride == null) {
          return TrackDriverPageLoader(
            rideId: extra is String ? extra : null,
            trackRepository: Modular.get<TrackRepository>(),
            chatRepositoryFactory: Modular.get<ChatRepositoryFactory>(),
            sessionService: Modular.get<SessionStore>(),
            lifecycleCoordinator: Modular.get<AppLifecycleCoordinator>(),
            liveMapBloc: Modular.get<LiveMapBloc>(),
            onRideTerminated: onRideTerminated,
            realtimeClient: Modular.get<RealtimeWebSocketClient>(),
          );
        }
        return TrackDriverPage(
          ride: ride,
          trackRepository: Modular.get<TrackRepository>(),
          chatRepositoryFactory: Modular.get<ChatRepositoryFactory>(),
          sessionService: Modular.get<SessionStore>(),
          lifecycleCoordinator: Modular.get<AppLifecycleCoordinator>(),
          liveMapBloc: Modular.get<LiveMapBloc>(),
          onRideTerminated: onRideTerminated,
          realtimeClient: Modular.get<RealtimeWebSocketClient>(),
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: ActiveRideRoutes.passengerPayment,
      ActiveRideRoutes.passengerPaymentPath,
      child: (context, GoRouterState state) {
        final extra = state.extra;
        return extra is! RideSnapshot
            ? const Scaffold(
                body: Center(child: Text('Payment data unavailable.')),
              )
            : PaymentPage(ride: extra);
      },
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [];
}

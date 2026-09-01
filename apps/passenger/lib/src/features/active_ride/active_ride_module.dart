import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/active_ride/active_ride_routes.dart';
import 'package:passenger/src/features/active_ride/data/data_sources/ride_remote_data_source.dart';
import 'package:passenger/src/features/active_ride/data/repositories/track_repository_impl.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver/track_driver_cubit.dart';
import 'package:passenger/src/features/active_ride/presentation/view/driver_matched_page.dart';
import 'package:passenger/src/features/active_ride/presentation/view/track_driver_page.dart';
import 'package:passenger/src/features/chat/chat.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';
import 'package:passenger/src/infrastructure/telemetry/passenger_background_telemetry.dart';

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
      )
      ..addFactory<LiveMapBloc>(
        (i) => LiveMapBloc(trackRepository: i.get<TrackRepository>()),
      )
      ..addFactory<TrackDriverCubit>(
        (i) => TrackDriverCubit(
          repository: i.get<TrackRepository>(),
          sessionService: i.get<PassengerSessionStore>(),
          lifecycleCoordinator: i.get<AppLifecycleCoordinator>(),
          backgroundTelemetryService: i.get<PassengerBackgroundTelemetry>(),
        ),
      );
  }

  static List<ModularRoute> routes = [
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
          rideType: data.string('rideType') ?? 'Solo Ride',
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
          createdRide: data.object<RideHistory>('createdRide'),
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
        final ride = state.extra is RideHistory
            ? state.extra as RideHistory
            : null;
        if (ride == null) {
          return const Scaffold(
            body: Center(child: Text('Trip tracking data not available.')),
          );
        }
        return TrackDriverPage(
          ride: ride,
          trackRepository: Modular.get<TrackRepository>(),
          chatRepositoryFactory: Modular.get<ChatRepositoryFactory>(),
          sessionService: Modular.get<PassengerSessionStore>(),
          lifecycleCoordinator: Modular.get<AppLifecycleCoordinator>(),
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [];
}

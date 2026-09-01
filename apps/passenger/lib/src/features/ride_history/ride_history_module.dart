import 'package:passenger/src/features/ride_history/ride_history.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/infrastructure/session/passenger_session_store.dart';
import 'package:passenger/src/features/ride_history/ride_history_routes.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_history/ride_history_bloc.dart';
import 'package:passenger/src/features/ride_history/data/data_sources/passenger_ride_history_remote_data_source.dart';
import 'package:passenger/src/features/ride_history/data/repositories/ride_history_repository_impl.dart';
import 'package:passenger/src/features/ride_history/domain/repositories/ride_history_repository.dart';
import 'package:passenger/src/features/ride_history/presentation/view/ride_history_page.dart';
import 'package:passenger/src/features/ride_history/presentation/view/passenger_payment_page.dart';
import 'package:passenger/src/features/ride_history/presentation/view/passenger_rating_page.dart';
import 'package:passenger/src/features/ride_history/presentation/view/ride_details_page.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:design_system/design_system.dart';

class RideHistoryModule {
  RideHistoryModule._();

  static void binds(Injector i) {
    i
      ..addLazySingleton<PassengerRideHistoryRemoteDataSource>(
        (i) => PassengerRideHistoryRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<RideHistoryRepository>(
        (i) => RideHistoryRepositoryImpl(
          remoteDataSource: i.get<PassengerRideHistoryRemoteDataSource>(),
        ),
      )
      ..addFactory<RideHistoryBloc>(
        (i) => RideHistoryBloc(repository: i.get<RideHistoryRepository>()),
      );
  }

  static List<ModularRoute> routes = [
    ChildRoute(
      name: RideHistoryRoutes.rideDetails,
      RideHistoryRoutes.rideDetailsPath,
      child: (context, GoRouterState state) {
        final ride = state.extra is RideHistory
            ? state.extra as RideHistory
            : null;
        return RideDetailsPage(
          ride: ride,
          trackRepository: Modular.get<TrackRepository>(),
          sessionService: Modular.get<PassengerSessionStore>(),
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: RideHistoryRoutes.passengerRating,
      RideHistoryRoutes.passengerRatingPath,
      child: (context, GoRouterState state) {
        final driverId = state.uri.queryParameters['driverId'] ?? '';
        final driverName = state.uri.queryParameters['driverName'] ?? '';
        final rideId = state.uri.queryParameters['rideId'] ?? '';
        return PassengerRatingPage(
          driverId: driverId,
          driverName: driverName,
          rideId: rideId,
          profileRepository: Modular.get<DriverProfileRepository>(),
        );
      },
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
    ChildRoute(
      name: RideHistoryRoutes.passengerPayment,
      RideHistoryRoutes.passengerPaymentPath,
      child: (context, GoRouterState state) {
        final ride = state.extra is RideHistory
            ? state.extra as RideHistory
            : null;
        return ride == null
            ? const Scaffold(
                body: Center(child: Text('Payment data unavailable.')),
              )
            : PassengerPaymentPage(ride: ride);
      },
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
  ];

  static List<ModularRoute> shellRoutes = [
    ChildRoute(
      name: RideHistoryRoutes.rideHistory,
      RideHistoryRoutes.rideHistoryPath,
      child: (context, GoRouterState state) => BlocProvider<RideHistoryBloc>(
        create: (_) => Modular.get<RideHistoryBloc>(),
        child: const RideHistoryPage(),
      ),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}

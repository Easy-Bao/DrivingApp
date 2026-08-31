import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/activity/activity_routes.dart';
import 'package:passenger_app/src/features/activity/presentation/bloc/activity/activity_bloc.dart';
import 'package:passenger_app/src/features/activity/data/data_sources/passenger_activity_remote_data_source.dart';
import 'package:passenger_app/src/features/activity/data/repositories/activity_repository.dart';
import 'package:passenger_app/src/features/activity/domain/repositories/i_activity_repository.dart';
import 'package:passenger_app/src/features/activity/presentation/passenger_activity_page.dart';
import 'package:passenger_app/src/features/activity/presentation/passenger_payment_page.dart';
import 'package:passenger_app/src/features/activity/presentation/passenger_rating_page.dart';
import 'package:passenger_app/src/features/activity/presentation/view_details_page.dart';
import 'package:passenger_app/src/features/driver_profile/domain/repositories/i_driver_profile_repository.dart';
import 'package:passenger_app/src/features/trip/domain/repositories/i_track_repository.dart';
import 'package:passenger_app/src/features/trip/presentation/track_driver_page.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

class ActivityModule {
  ActivityModule._();

  static void binds(Injector i) {
    i
      ..addLazySingleton<PassengerActivityRemoteDataSource>(
        (i) => PassengerActivityRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<IActivityRepository>(
        (i) => ActivityRepository(
          remoteDataSource: i.get<PassengerActivityRemoteDataSource>(),
        ),
      )
      ..addFactory<ActivityBloc>(
        (i) => ActivityBloc(repository: i.get<IActivityRepository>()),
      );
  }

  static List<ModularRoute> routes = [
    ChildRoute(
      name: ActivityRoutes.activityViewDetails,
      ActivityRoutes.activityViewDetailsPath,
      child: (context, GoRouterState state) {
        final ride = state.extra is RideHistoryModel
            ? state.extra as RideHistoryModel
            : null;
        return ActivityViewDetailsPage(
          ride: ride,
          trackRepository: Modular.get<ITrackRepository>(),
          sessionService: Modular.get<SecureSessionService>(),
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: ActivityRoutes.activityTrackDriver,
      ActivityRoutes.activityTrackDriverPath,
      child: (context, GoRouterState state) {
        final ride = state.extra is RideHistoryModel
            ? state.extra as RideHistoryModel
            : null;
        if (ride == null) {
          return const Scaffold(
            body: Center(child: Text('Trip tracking data not available.')),
          );
        }
        return ActivityTrackDriverPage(
          ride: ride,
          trackRepository: Modular.get<ITrackRepository>(),
          chatRepositoryFactory: Modular.get<IChatRepositoryFactory>(),
          sessionService: Modular.get<SecureSessionService>(),
          lifecycleCoordinator: Modular.get<AppLifecycleCoordinator>(),
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: ActivityRoutes.passengerRating,
      ActivityRoutes.passengerRatingPath,
      child: (context, GoRouterState state) {
        final driverId = state.uri.queryParameters['driverId'] ?? '';
        final driverName = state.uri.queryParameters['driverName'] ?? '';
        final rideId = state.uri.queryParameters['rideId'] ?? '';
        return PassengerRatingPage(
          driverId: driverId,
          driverName: driverName,
          rideId: rideId,
          profileRepository: Modular.get<IDriverProfileRepository>(),
        );
      },
      transition: AppTransitions.modal.toTop,
      transitionDuration: AppTransitions.modalDuration,
    ),
    ChildRoute(
      name: ActivityRoutes.passengerPayment,
      ActivityRoutes.passengerPaymentPath,
      child: (context, GoRouterState state) {
        final ride = state.extra is RideHistoryModel
            ? state.extra as RideHistoryModel
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
      name: ActivityRoutes.activity,
      ActivityRoutes.activityPath,
      child: (context, GoRouterState state) => BlocProvider<ActivityBloc>(
        create: (_) => Modular.get<ActivityBloc>(),
        child: const PassengerActivityPage(),
      ),
      transition: AppTransitions.none,
      transitionDuration: Duration.zero,
    ),
  ];
}

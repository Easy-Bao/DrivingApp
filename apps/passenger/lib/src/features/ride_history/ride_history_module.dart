import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/domain/entities/ride_snapshot.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';
import 'package:passenger/src/features/ride_history/data/datasources/ride_history_remote_data_source.dart';
import 'package:passenger/src/features/ride_history/data/repositories/ride_history_repository_impl.dart';
import 'package:passenger/src/features/ride_history/domain/repositories/ride_history_repository.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_details/ride_details_cubit.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_history/ride_history_bloc.dart';
import 'package:passenger/src/features/ride_history/presentation/pages/recent_activity_page.dart';
import 'package:passenger/src/features/ride_history/presentation/pages/ride_details_page.dart';
import 'package:passenger/src/features/ride_history/presentation/pages/ride_history_page.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';
import 'package:passenger/src/features/ride_history/ride_history_routes.dart';

class RideHistoryModule._() {
  static void binds(Injector i) {
    i
      ..addLazySingleton<RideHistoryRemoteDataSource>(
        (i) => RideHistoryRemoteDataSourceImpl(i.get<Dio>()),
      )
      ..addLazySingleton<RideHistoryRepository>(
        (i) => RideHistoryRepositoryImpl(
          remoteDataSource: i.get<RideHistoryRemoteDataSource>(),
        ),
      )
      ..addFactory<RideHistoryBloc>(
        (i) => RideHistoryBloc(
          repository: i.get<RideHistoryRepository>(),
          sessionBloc: i.get<SessionBloc>(),
        ),
      )
      ..addFactory<RideDetailsCubit>(
        (i) => RideDetailsCubit(
          repository: i.get<TrackRepository>(),
          sessionService: i.get<SessionStore>(),
          profileRepository: i.get<DriverProfileRepository>(),
        ),
      );
  }

  static List<ModularRoute> routes = [
    ChildRoute(
      name: RideHistoryRoutes.recentActivity,
      RideHistoryRoutes.recentActivityPath,
      child: (context, GoRouterState state) => BlocProvider<RideHistoryBloc>(
        create: (_) => Modular.get<RideHistoryBloc>(),
        child: const RecentActivityPage(),
      ),
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: RideHistoryRoutes.rideDetails,
      RideHistoryRoutes.rideDetailsPath,
      child: (context, GoRouterState state) {
        final extra = state.extra;
        final ride = extra is RideHistory ? extra : null;
        final initialRide = extra is RideSnapshot ? extra : null;
        return RideDetailsPage(
          ride: ride,
          rideId: ride?.id ?? initialRide?.id,
          initialRide: initialRide,
          trackRepository: Modular.get<TrackRepository>(),
          sessionService: Modular.get<SessionStore>(),
          profileRepository: Modular.get<DriverProfileRepository>(),
          detailsCubit: Modular.get<RideDetailsCubit>(),
        );
      },
      transition: AppTransitions.push.toLeft,
      transitionDuration: AppTransitions.pushDuration,
    ),
    ChildRoute(
      name: RideHistoryRoutes.passengerRating,
      RideHistoryRoutes.passengerRatingPath,
      child: (context, GoRouterState state) {
        final rideId = state.uri.queryParameters['rideId'] ?? '';
        return RideDetailsPage(
          rideId: rideId,
          trackRepository: Modular.get<TrackRepository>(),
          sessionService: Modular.get<SessionStore>(),
          profileRepository: Modular.get<DriverProfileRepository>(),
          detailsCubit: Modular.get<RideDetailsCubit>(),
        );
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

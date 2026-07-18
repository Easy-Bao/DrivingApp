import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/activity/data/repositories/activity_repository_impl.dart';
import 'package:passenger_app/src/features/booking/data/repositories/driver_repository_impl.dart';
import 'package:passenger_app/src/features/home/data/repositories/passenger_home_repository_impl.dart';
import 'package:passenger_app/src/features/saved_places/data/repositories/saved_places_repository_impl.dart';
import 'package:passenger_app/src/features/booking/data/repositories/track_repository_impl.dart';
import 'package:passenger_app/src/features/activity/domain/repositories/activity_repository.dart';
import 'package:passenger_app/src/features/saved_places/domain/repositories/saved_places_repository.dart';
import 'package:passenger_app/src/features/profile/profile_module.dart';
import 'package:passenger_app/src/features/activity/activity_module.dart';
import 'package:passenger_app/src/features/home/home_module.dart';
import 'package:passenger_app/src/features/activity/presentation/bloc/activity_bloc.dart';
import 'package:passenger_app/src/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:passenger_app/src/features/home/presentation/bloc/passenger_home_cubit.dart';
import 'package:passenger_app/src/features/saved_places/presentation/bloc/saved_places_cubit.dart';
import 'package:passenger_app/src/features/booking/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:passenger_app/src/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:passenger_app/src/features/booking/presentation/bloc/track_driver/track_driver_cubit.dart';
import 'package:passenger_app/src/features/saved_places/presentation/screens/favorites_management_screen.dart';
import 'package:passenger_app/src/features/profile/presentation/screens/passenger_account_screen.dart';
import 'package:passenger_app/src/features/home/presentation/screens/notification_screen.dart';
import 'package:passenger_app/src/features/booking/trip_routes.dart';
import 'package:passenger_app/src/shared/widgets/navigationbar/passenger_tab.dart';
import 'package:passenger_services/passenger_services.dart';
import 'package:session_service/session_service.dart';
import 'package:shared_ui/transitions/passenger_transitions.dart';

class PassengerModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i
      ..addLazySingleton<DriverRepository>(
        (i) => DriverRepositoryImpl(apiService: i.get<PassengerApiService>()),
      )
      ..addLazySingleton<TrackRepository>(
        (i) => TrackRepositoryImpl(apiService: i.get<PassengerApiService>()),
      )
      ..addLazySingleton<PassengerHomeRepository>(
        (i) => PassengerHomeRepositoryImpl(
          apiService: i.get<PassengerApiService>(),
        ),
      )
      ..addLazySingleton<SavedPlacesRepository>(
        (i) => SavedPlacesRepositoryImpl(),
      )
      ..addLazySingleton<ActivityRepository>(
        (i) => ActivityRepositoryImpl(apiService: i.get<PassengerApiService>()),
      )
      ..addLazySingleton<BidSessionService>(
        (i) => BidSessionService(apiService: i.get<PassengerApiService>()),
      )
      ..addFactory<SavedPlacesCubit>(
        (i) => SavedPlacesCubit(repository: i.get<SavedPlacesRepository>()),
      )
      ..addFactory<ActivityBloc>(
        (i) => ActivityBloc(repository: i.get<ActivityRepository>()),
      )
      ..addFactory<BookingBloc>(
        (i) => BookingBloc(
          driverRepository: i.get<DriverRepository>(),
          bidSessionService: i.get<BidSessionService>(),
          apiService: i.get<PassengerApiService>(),
        ),
      )
      ..addFactory<LiveMapBloc>(
        (i) => LiveMapBloc(apiService: i.get<PassengerApiService>()),
      )
      ..addFactory<ProfileCubit>(
        (i) => ProfileCubit(apiService: i.get<PassengerApiService>()),
      )
      ..addFactory<PassengerHomeCubit>(
        (i) => PassengerHomeCubit(
          repository: i.get<PassengerHomeRepository>(),
        ),
      )
      ..addFactory<TrackDriverCubit>(
        (i) => TrackDriverCubit(
          repository: i.get<TrackRepository>(),
          sessionService: i.get<SecureSessionService>(),
        ),
      );
  }
  final homeRoutes = [...HomeModule.shellRoutes];
  final homeRoutesScreen = [...HomeModule.routes];

  final activityRoutes = [...ActivityModule.shellRoutes];
  final activityRoutesScreen = [...ActivityModule.routes];

  final accountRoutesScreen = [...AccountModule.routes];

  static List<ModularRoute> get route => <ModularRoute>[...HomeModule.routes];

  @override
  List<ModularRoute> get routes => <ModularRoute>[
    // Independent Screen
    ...activityRoutesScreen,
    ...homeRoutesScreen,
    ...accountRoutesScreen,
    ShellModularRoute(
      builder: (context, GoRouterState state, child) =>
          PassengerShellLayout(child: child),
      routes: [
        ...homeRoutes,
        ...activityRoutes,
        ChildRoute(
          name: TripRoutes.passengerAccount,
          'account',
          child: (context, GoRouterState state) =>
              const PassengerAccountScreen(),
          transition: AppTransitions.none,
          transitionDuration: Duration.zero,
        ),
        ChildRoute(
          name: TripRoutes.passengerHelp,
          'help',
          child: (context, GoRouterState state) => BlocProvider<SavedPlacesCubit>(
            create: (_) => Modular.get<SavedPlacesCubit>(),
            child: const FavoritesManagementScreen(),
          ),
          transition: AppTransitions.none,
          transitionDuration: Duration.zero,
        ),
        ChildRoute(
          name: TripRoutes.notifications,
          'notifications',
          child: (context, GoRouterState state) =>
              const NotificationScreen(),
          transition: AppTransitions.none,
          transitionDuration: Duration.zero,
        ),
      ],
    ),
  ];
}

import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/activity/activity_module.dart';
import 'package:passenger_app/src/features/activity/data/repositories/activity_repository_impl.dart';
import 'package:passenger_app/src/features/activity/domain/repositories/activity_repository.dart';
import 'package:passenger_app/src/features/activity/presentation/bloc/activity_bloc.dart';
import 'package:passenger_app/src/features/chat/chat_module.dart';
import 'package:passenger_app/src/features/home/data/repositories/passenger_home_repository_impl.dart';
import 'package:passenger_app/src/features/home/home_module.dart';
import 'package:passenger_app/src/features/home/presentation/bloc/passenger_home_cubit.dart';
import 'package:passenger_app/src/features/inbox/inbox_module.dart';
import 'package:passenger_app/src/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:passenger_app/src/features/profile/profile_module.dart';
import 'package:passenger_app/src/features/saved_places/data/repositories/saved_places_repository_impl.dart';
import 'package:passenger_app/src/features/saved_places/domain/repositories/saved_places_repository.dart';
import 'package:passenger_app/src/features/saved_places/presentation/bloc/saved_places_cubit.dart';
import 'package:passenger_app/src/features/settings/settings_module.dart';
import 'package:passenger_app/src/features/trip/data/repositories/driver_repository_impl.dart';
import 'package:passenger_app/src/features/trip/data/repositories/track_repository_impl.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/booking_bloc.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/live_map/live_map_bloc.dart';
import 'package:passenger_app/src/features/trip/presentation/bloc/track_driver/track_driver_cubit.dart';
import 'package:passenger_app/src/features/trip/trip_module.dart';
import 'package:passenger_app/src/shared/widgets/navigationbar/passenger_tab.dart';
import 'package:passenger_services/passenger_services.dart';
import 'package:session_service/session_service.dart';

class PassengerModule extends Module {
  @override
  FutureOr<void> binds(Injector i) {
    i
      ..addLazySingleton<DriverRepository>(
        (i) => DriverRepositoryImpl(
          biddingDataSource: i.get<BiddingRemoteDataSource>(),
        ),
      )
      ..addLazySingleton<TrackRepository>(
        (i) => TrackRepositoryImpl(
          biddingDataSource: i.get<BiddingRemoteDataSource>(),
        ),
      )
      ..addLazySingleton<PassengerHomeRepository>(
        (i) => PassengerHomeRepositoryImpl(
          passengerRemoteDataSource: i.get<PassengerRemoteDataSource>(),
        ),
      )
      ..addLazySingleton<SavedPlacesRepository>(
        (i) => SavedPlacesRepositoryImpl(),
      )
      ..addLazySingleton<ActivityRepository>(
        (i) => ActivityRepositoryImpl(
          passengerRemoteDataSource: i.get<PassengerRemoteDataSource>(),
        ),
      )
      ..addLazySingleton<BidSessionService>(
        (i) => BidSessionService(
          biddingRepository: i.get<BiddingRepository>(),
        ),
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
          biddingDataSource: i.get<BiddingRemoteDataSource>(),
        ),
      )
      ..addFactory<LiveMapBloc>(
        (i) => LiveMapBloc(
          biddingDataSource: i.get<BiddingRemoteDataSource>(),
        ),
      )
      ..addFactory<ProfileCubit>(
        (i) => ProfileCubit(
          profileRepository: i.get<PassengerProfileRepository>(),
        ),
      )
      ..addFactory<PassengerHomeCubit>(
        (i) => PassengerHomeCubit(repository: i.get<PassengerHomeRepository>()),
      )
      ..addFactory<TrackDriverCubit>(
        (i) => TrackDriverCubit(
          repository: i.get<TrackRepository>(),
          sessionService: i.get<SecureSessionService>(),
        ),
      );
  }

  @override
  List<ModularRoute> get routes => <ModularRoute>[
        ...ActivityModule.routes,
        ...TripModule.routes,
        ...ChatModule.routes,
        ...ProfileModule.routes,
        ...SettingsModule.routes,

        ShellModularRoute(
          builder: (context, GoRouterState state, child) =>
              PassengerShellLayout(child: child),
          routes: [
            ...HomeModule.shellRoutes,
            ...ActivityModule.shellRoutes,
            ...ProfileModule.shellRoutes,
            ...InboxModule.shellRoutes,
          ],
        ),
      ];
}
